# Graph-based news representation

뉴스 제목을 **노드**, 겹치는 단어를 **엣지**의 **가중치**로 표현해 중요 기사를 거르는 방법론을 구현했습니다. 자세한 내용은 [이곳](https://ratsgo.github.io/natural%20language%20processing/2017/03/13/graphnews/)을 참고하시고요, 코드 개요는 아래와 같습니다. (기본 작업 디렉토리는 'C:/NEWS'로 설정돼 있으며 A, B, C, D, E 순서대로 실행하시면 됩니다)

- A_crawling.R : 기사를 크롤링하는 코드입니다.
- B_preprocessing.R : 형태소분석 등 텍스트 전처리용 코드입니다.
- C_newsgraph.R : 뉴스 그래프를 생성하는 코드입니다.
- D_topic extract_lda.R : 토픽모델링으로 뉴스 컨텐츠를 분류하는 코드입니다.
- E_search.R : 분석 내용 전체에서 쿼리 단어에 맞는 뉴스컨텐츠를 찾아주는 코드입니다.