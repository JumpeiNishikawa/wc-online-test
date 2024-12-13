from pykakasi import kakasi
import re


def convert_kata(word):
    # オブジェクトをインスタンス化
    kks = kakasi()
    
    # 変換して出力
    conv = kks.convert(word)
    res = ""
    for item in conv:
        res = res + item["kana"]
    #print(res)
    return res





with open("D_data.csv" ) as file1, open("1_rensougoi01.csv") as file2:
    data1 =  file1.readlines()
    data2 = file2.readlines()

    data1 = [d.split(",")[4] for d in data1]
    data2 = [d.split(",")[3] for d in data2 if d.split(",")[2] != "成人"]

    data1 = list(set(data1))
    data2 = [convert_kata(d) for d in data2]
    data2 = list(set(data2))

    tmp = []

    for d in data2:
        if d in data1:
            tmp.append(d)
    
    print("kihongo: " + str(len(data1)))
    print("rensou: " + str(len(data2)))
    print("common: " + str(len(tmp)))
    
    print(tmp) #この結果をmake_base_levels.pyに貼り付けて利用する #ながすぎでできんかったわ
    
    