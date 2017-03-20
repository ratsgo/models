# advanced Rotation Forest

고려대학교 산업경영공학부 [데이터사이언스&비즈니스어낼리틱스 연구실](http://dsba.korea.ac.kr)에서 만든 Rotation Forest 함수입니다. R에서 작동하며 **rotationforest.R** 파일을 열어서 쓰면 됩니다. 사용법은 다음과 같고요, 자세한 내용은 **[이곳](https://ratsgo.github.io/machine%20learning/2017/03/17/tree/)**을 참고하시기 바랍니다.

```R
Fit <- rotationForest(data, k, numTrees, bootstrapRate, type)
Result <- rf.predict(model, newdata, method, type)
```

- 데이터의 마지막 열=y, 나머지 열=x

- k=부분집합개수

- bootstrapRate=부트스트랩할 때레코드 선택 비율

- numTrees=트리 수

- type=분류(class)/회귀(regression)선택

- method=분류 예측시 각트리의 결과물을 어떻게 취합할지 결정

  ​                 max.prob : 특정클래스에 속할 확률의 총합, max.vote : 각 트리가 내놓는 클래스의 다수결 결과


- 범주형변수는 자동으로 더미변수화
- 다범주분류, 회귀모두 가능