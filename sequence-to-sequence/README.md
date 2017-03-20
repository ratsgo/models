# Sequence-to-Sequence Models

Sequence-to-Sequence Model을 뉴스 제목 추출하기에 접목해본 코드입니다. [텐서플로우](https://www.tensorflow.org/versions/r0.12/tutorials/seq2seq/) 예제를 커스터마이징해서 만들었고요, 텍스트 전처리 코드는 김현중 서울대 박사과정께서 만드신 [코드](https://github.com/lovit/soy/tree/master/soy/nlp)를 활용했습니다. 자세한 내용은 제 [블로그](https://ratsgo.github.io/natural%20language%20processing/2017/03/12/s2s/)에서 확인하실 수 있습니다. 파일 구성은 다음과 같습니다.

- news_seq2seq.py : Sequence-to-Sequence Model이 구현된 코드입니다.
- tool.py : news_seq2seq.py가 불러서 쓰는 사용자 정의함수를 모아 놓았습니다.
- newscorpus.csv : 토이 데이터셋으로 쓰는 기사 모음입니다. 저작권 문제가 생길시 자삭하겠습니다.