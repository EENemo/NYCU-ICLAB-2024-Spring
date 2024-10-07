## NYCU-ICLAB-2024-Spring Lab 分享目錄
1. [摘要](#摘要)
2. [課程介紹](#課程介紹)
3. [前言](#前言)
4. [背景](#背景)

## 摘要
##### 想說的話
架構圖對於數位設計來說非常重要，初學verilog都會聽到要先有架構再來寫code。我覺得這句話說得非常好，因為電路是平行運行，要想辦法最大使用訊號線，才能讓電路的優勢凸顯出來，而非用軟體逐行執行的概念撰寫，而畫電路架構可以讓自己的腦袋更清楚訊號線的流向。

我覺得畫架構圖很有趣，在iclab中的每個架構圖也不是一版成型，而是經過一版再一版的各種優化，才有了最終比較好的performance，第一版通常都超爛，經過當了一個學期的小畫家，我除了再數位IC相關方面的知識有更了解外，對於訊號流向也更敏感，所以我蠻推薦練習畫架構圖。

寫code的時候，心中要有MUX，你懂MUX，MUX就會幫你。

若有更好的想法，歡迎討論

信箱: a0921338454@gamil.com

##### 個人成績
- 原始分數：88.46
- 等第：A+
- 結算名次：18 / 127
  
|      | Lab01  | Lab02 | Lab03 | Lab04 | Lab05 | Lab06 |OT |    MIDTERM PROJECT | MID EXAM |
| ------------|:------:|:-----:|:-----:|:-----:|:-----:|:-----:|:--------------:|:-----:|:-------:|
| Score       |97.89|95.6|100|98.11|51.52|99.39|50|72.76|85|
-------------------------
|     | Lab07  | Lab08 | Lab09 | Lab10 Bonus | Lab11 | Lab12 | LAB13|   FINAL PROJECT  | FINAL EXAM |
| ------------|:------:|:-----:|:-----:|:-----:|:-----:|:-----:|:--------------:|:-----:|:-------:|
| Score       |99.32|95.48|98.67|100|90.47|81.27|100|98.26|88.7|

>*Lab5 唯一2de*

>*Lab11 Naming error*


## 課程介紹
##### 該學期課程資訊
- 課程名稱：積體電路設計實驗 Integrated Circuit Design Laboratory
- 課程簡評：這是一門非常精實的數位 IC 設計課程，設計流程從 RTL 到 GDS 皆會接觸，實驗使用商用設計軟體以及 .18 製程合成，以 PPA 排名做為評分準則。
- 扣除退選全班平均：78.92 分
- 學期初總修課人數：127 人
- 退選人數：38 人
- 調分：約莫 2 分
- 授課語言：英文
>*退選人數是用期末考缺考人數估計*

>*每人調分幅度未必相同，僅供參考*

>*期中期末考無額外加分*

>*部分實驗題目是考古題，通過率提升但 RANK 更競爭*

##### 課程內容
| Lecture | Topic |
|:--|:--:|
|Lecture01|Cell Based Design Methodology + Verilog Combinational Circuit Programming|
|Lecture02|Finite State Machine + Verilog Sequential Circuit Programming |
|Lecture03|Verification & Simulation + Verilog Test Bench Programming |
|Lecture04|Sequential Circuit Design II (STA + Pipeline) |
|Lecture05|Memory & Coding Style (Memory Compiler + SuperLint)|
|Lecture06|Synthesis Methodology (Design Compiler + IP Design)|
|Lecture07|Timing: Cross Clock Domain + Synthesis Static Time Analysis|
|Lecture08|System Verilog - RTL Design|
|Lecture09|System Verilog - Verification|
|Lecture10|System Verilog - Formal Verification|
|Lecture11|Power Analysis & Low Power Design|
|Lecture12|APR I : From RTL to GDSII|
|Lecture13|APR II: IR-Drop Analysis|

##### 課程實驗
| Lab | Topic | Pass Rate |
|:--|:--:|:--:|
|[Lab01](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab01")|Code Calculator|89.76%|
|[Lab02](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab02")|Enigma Machine|85.83%|
|[Lab03](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab03")|AXI-SPI DataBridge|75.59%|
|[Lab04](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab04")|Convolution Neural Network|74.80%|
|[Lab05](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab05")|Matrix convolution, max pooling and transposed convolution|59.06%|
|[Lab06](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab06")|Huffman Code Operation|77.95%|
|[Lab07](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab07")|Matrix Multiplication with Clock Domain Crossing|74.80%|
|[Lab08](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab08")|Design: Tea House|66.14%|
|[Lab09](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab09")|Verification: Tea House|66.14%|
|[Lab10](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab10")|Formal Verification|76.38%|
|[Lab11](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab11")|Low power design: Siamese Neural Network|67.72%|
|[Lab12](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab12")|APR: Matrix convolution, max pooling and transposed convolution|68.50%|
|[Lab13](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/Lab13")|Train Tour APRII|68.50%|
|[Online Test](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/OT")|Infix to prefix convertor and prefix evaluation|2.36%|
|[Midtern Project](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/MP")|Maze Router Accelerator|68.50%|
|[Final Project](<https://github.com/EENemo/NYCU-ICLAB-2024-Spring/tree/main/Mycode/Lab01_iclab048> "Mycode/FP")|single core CPU|67.72%|

## 背景
##### 在 iclab 之前修過哪些課
- 電子碩-SOC 系統晶片設計 
- 電子碩-CA 計算機結構   
- 電控碩-VLSI 超大型積體電路設計
- 電子碩-DIC 數位積體電路
- 電子碩-MLIC 機器學習智能晶片設計
- 電控碩-AFPGA 進階可程式邏輯系統設計與應用
- 張添烜教授數位電路與系統的YT影片 (大推)

