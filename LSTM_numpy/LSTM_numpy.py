import numpy as np

'''
# data I/O (char)
data = open('input.txt', 'r', encoding='utf-8').read()  # should be simple plain text file
chars = list(set(data))
data_size, vocab_size = len(data), len(chars)
char_to_ix = {ch: i for i, ch in enumerate(chars)}
ix_to_char = {i: ch for i, ch in enumerate(chars)}
'''

# data I/O (word)
corpus = open('input.txt', 'r', encoding='utf-8').read()  # should be simple plain text file
data = corpus.split()
words = list(set(data))
data_size, vocab_size = len(data), len(words)
char_to_ix = {ch: i for i, ch in enumerate(words)}
ix_to_char = {i: ch for i, ch in enumerate(words)}

# hyperparameters
hidden_size = 100  # size of hidden layer of neurons
seq_length = 25 # number of steps to unroll the RNN for / 한번에 처리할 문자 개수
learning_rate = 1e-1

# model parameters
Wxh = np.random.randn(4 * hidden_size, vocab_size) * 0.01  # input to hidden
Whh = np.random.randn(4 * hidden_size, hidden_size) * 0.01  # hidden to hidden
Why = np.random.randn(vocab_size, hidden_size) * 0.01  # hidden to output
bh = np.zeros((4 * hidden_size, 1))  # hidden bias
by = np.zeros((vocab_size, 1))  # output bias

def sigmoid(x):
    pos_mask = (x >= 0)
    neg_mask = (x < 0)
    z = np.zeros_like(x)
    z[pos_mask] = np.exp(-x[pos_mask])
    z[neg_mask] = np.exp(x[neg_mask])
    top = np.ones_like(x)
    top[neg_mask] = z[neg_mask]
    return top / (1 + z)

def lossFun(inputs, targets, hprev, cprev):
    """
    inputs,targets are both list of integers.
    hprev is Hx1 array of initial hidden state
    returns the loss, gradients on model parameters, and last hidden state
    """
    xs, hs, cs, is_, fs, os, gs, ys, ps = {}, {}, {}, {}, {}, {}, {}, {}, {}
    hs[-1] = np.copy(hprev) # t=0일때 t-1 시점의 hidden state가 필요하므로
    cs[-1] = np.copy(cprev)
    loss = 0
    H = hidden_size
    # forward pass (compute loss)
    for t in range(len(inputs)):
        xs[t] = np.zeros((vocab_size, 1))  # encode in 1-of-k representation
        xs[t][inputs[t]] = 1
        tmp = np.dot(Wxh, xs[t]) + np.dot(Whh, hs[t - 1]) + bh  # hidden state
        is_[t] = sigmoid(tmp[:H])
        fs[t] = sigmoid(tmp[H:2 * H])
        os[t] = sigmoid(tmp[2 * H: 3 * H])
        gs[t] = np.tanh(tmp[3 * H:])
        cs[t] = fs[t] * cs[t-1] + is_[t] * gs[t]
        hs[t] = os[t] * np.tanh(cs[t])
        ys[t] = np.dot(Why, hs[t]) + by  # unnormalized log probabilities for next chars
        ps[t] = np.exp(ys[t]) / np.sum(np.exp(ys[t]))  # probabilities for next chars
        loss += -np.log(ps[t][targets[t], 0])  # softmax (cross-entropy loss), 왜 targets[t]가 들어가지??
    # backward pass: compute gradients going backwards
    dWxh, dWhh, dWhy = np.zeros_like(Wxh), np.zeros_like(Whh), np.zeros_like(Why)
    dbh, dby = np.zeros_like(bh), np.zeros_like(by)
    dhnext, dcnext = np.zeros_like(hs[0]), np.zeros_like(hs[0])
    for t in reversed(range(len(inputs))):
        dy = np.copy(ps[t])
        dy[targets[t]] -= 1  # backprop into y
        dWhy += np.dot(dy, hs[t].T)
        dby += dy
        dh = np.dot(Why.T, dy) + dhnext # backprop into h
        dc = dcnext + (1 - np.tanh(cs[t]) * np.tanh(cs[t])) * dh * os[t]  # backprop through tanh nonlinearity
        dcnext = dc * fs[t]
        di = dc * gs[t]
        df = dc * cs[t-1]
        do = dh * np.tanh(cs[t])
        dg = dc * is_[t]
        ddi = (1 - is_[t]) * is_[t] * di
        ddf = (1 - fs[t]) * fs[t] * df
        ddo = (1 - os[t]) * os[t] * do
        ddg = (1 - np.tanh(gs[t]) * np.tanh(gs[t])) * dg
        da = np.hstack((ddi.ravel(),ddf.ravel(),ddo.ravel(),ddg.ravel()))
        dWxh += np.dot(da[:,np.newaxis],xs[t].T)
        dWhh += np.dot(da[:,np.newaxis],hs[t-1].T)
        dbh += da[:, np.newaxis]
        dhnext = np.dot(Whh.T, da[:, np.newaxis])
    for dparam in [dWxh, dWhh, dWhy, dbh, dby]:
        np.clip(dparam, -5, 5, out=dparam)  # clip to mitigate exploding gradients
    return loss, dWxh, dWhh, dWhy, dbh, dby, hs[len(inputs) - 1], cs[len(inputs) - 1]


def sample(prevh, prevc, seed_ix, n):
    x = np.zeros((vocab_size, 1))
    x[seed_ix] = 1
    ixes = []
    c = prevc
    h = prevh
    H = hidden_size
    for t in range(n):
        tmp = np.dot(Wxh, x) + np.dot(Whh, h) + bh  # hidden state
        i = sigmoid(tmp[:H])
        f = sigmoid(tmp[H:2 * H])
        o = sigmoid(tmp[2 * H: 3 * H])
        g = np.tanh(tmp[3 * H:])
        c = f * c + i * g
        h = o * np.tanh(c)
        y = np.dot(Why, h) + by  # unnormalized log probabilities for next chars
        p = np.exp(y) / np.sum(np.exp(y))  # probabilities for next chars
        ix = np.random.choice(range(vocab_size), p=p.ravel())
        x = np.zeros((vocab_size, 1))
        x[ix] = 1
        ixes.append(ix)
    return ixes


n, p = 0, 0
mWxh, mWhh, mWhy = np.zeros_like(Wxh), np.zeros_like(Whh), np.zeros_like(Why)
mbh, mby = np.zeros_like(bh), np.zeros_like(by)  # memory variables for Adagrad
smooth_loss = -np.log(1.0 / vocab_size) * seq_length  # loss at iteration 0
while n < 1000001:
    # prepare inputs (we're sweeping from left to right in steps seq_length long)
    if p + seq_length + 1 >= len(data) or n == 0:
        hprev = np.zeros((hidden_size, 1))  # reset RNN memory
        cprev = np.zeros((hidden_size, 1))
        p = 0  # go from start of data
    inputs = [char_to_ix[ch] for ch in data[p:p + seq_length]] # 25글자씩을 index로 바꿈
    targets = [char_to_ix[ch] for ch in data[p + 1:p + seq_length + 1]] # 바로 다음 글자가 target이 됨

    # sample from the model now and then
    if n % 100 == 0:
        sample_ix = sample(hprev, cprev, inputs[0], 100)
        txt = ' '.join(ix_to_char[ix] for ix in sample_ix)
        print('----\n %s \n----' % (txt,))

    # forward seq_length characters through the net and fetch gradient
    # hprev is Hx1 array of initial hidden state
    loss, dWxh, dWhh, dWhy, dbh, dby, hprev, cprev = lossFun(inputs, targets, hprev, cprev)
    smooth_loss = smooth_loss * 0.999 + loss * 0.001
    if n % 100 == 0:
        print('iter %d, loss: %f' % (n, smooth_loss)) # print progress

    # perform parameter update with Adagrad
    for param, dparam, mem in zip([Wxh, Whh, Why, bh, by],
                                  [dWxh, dWhh, dWhy, dbh, dby],
                                  [mWxh, mWhh, mWhy, mbh, mby]):
        mem += dparam * dparam
        param += -learning_rate * dparam / np.sqrt(mem + 1e-8)  # adagrad update

    p += seq_length  # move data pointer
    n += 1  # iteration counter