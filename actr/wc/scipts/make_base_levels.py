import re
import jaconv
from pykakasi import kakasi

#チャンク作ってるpyファイルの同名の関数とは処理が異なるので注意
def select_noun(path):
    print("select_noun")
    with open(path) as raw_data:
        lines = raw_data.readlines()
        noun_dict = {}
        for line in lines:
            linelst = line.split(",")
            if not linelst[8].find("名") == -1:
                #print(linelst[4] + "," + linelst[8])
                noun_dict[linelst[4]] = linelst[6]

        return noun_dict

def replace_v(data):
    replaced_data = {}
    for i in data:
        replaced_data[i.replace("デュ","デユ").replace("ヴァ","バ").replace("ヴィ","ビ").replace("ヴ","ブ").replace("ヂ","ジ").replace("ヅ","ズ")] = data[i]
    return replaced_data

def replace_l(data):
    replaced_data = {}
    for i in data:
        replaced_data[i.replace("ァ","ア").replace("ィ","イ").replace("ゥ","ウ").replace("ェ","エ").replace("ォ","オ").replace("ヮ","ワ")] = data[i]
    return replaced_data

def convert_kata2alpha(arg_dict):
    mydict = make_kana_alpha_dict()
    mydict = dict(sorted(mydict.items(), reverse=True, key=lambda x : len(x[0])))

    result = {}
    for d in arg_dict:
        result[my_sub(mydict, d)] = arg_dict[d]
    return result

def make_kana_alpha_dict():
    #これを用意する関数も再度作成した方が良いなあ
    alpha = "a,i,u,e,o,ja,ju,jo,ka,ki,ku,ke,ko,kja,kju,kjo,ga,gi,gu,ge,go,gja,gju,gjo,sa,si,su,se,so,sja,sju,sjo,za,zi,zu,ze,zo,zja,zju,zjo,ta,ti,tu,te,to,tja,tju,tjo,da,de,do,na,ni,nu,ne,no,nja,nju,njo,ha,hi,hu,he,ho,hja,hju,hjo,pa,pi,pu,pe,po,pja,pju,pjo,ba,bi,bu,be,bo,bja,bju,bjo,ma,mi,mu,me,mo,mja,mju,mjo,ra,ri,ru,re,ro,rja,rju,rjo,wa,0,1,2"
    kana = "ア,イ,ウ,エ,オ,ヤ,ユ,ヨ,カ,キ,ク,ケ,コ,キャ,キュ,キョ,ガ,ギ,グ,ゲ,ゴ,ギャ,ギュ,ギョ,サ,シ,ス,セ,ソ,シャ,シュ,ショ,ザ,ジ,ズ,ゼ,ゾ,ジャ,ジュ,ジョ,タ,チ,ツ,テ,ト,チャ,チュ,チョ,ダ,デ,ド,ナ,ニ,ヌ,ネ,ノ,ニャ,ニュ,ニョ,ハ,ヒ,フ,ヘ,ホ,ヒャ,ヒュ,ヒョ,パ,ピ,プ,ペ,ポ,ピャ,ピュ,ピョ,バ,ビ,ブ,ベ,ボ,ビャ,ビュ,ビョ,マ,ミ,ム,メ,モ,ミャ,ミュ,ミョ,ラ,リ,ル,レ,ロ,リャ,リュ,リョ,ワ,ン,ー,ッ"
    #ui,ue,uo,sie,jie,tie,tei,dei,hua,hui,hue,huo,tua
    #ウィ,ウェ,ウォ,シェ,ジェ,チェ,ティ,ディ,ファ,フィ,フェ,フォ,ツァ,
    alpha_list = alpha.split(",")
    kana_list = kana.split(",")

    kana_alpha_dict = dict(zip(kana_list, alpha_list))

    #print(kana_alpha_dict)
    return kana_alpha_dict
def my_sub(dict, kana):
    return re.sub('({})'.format('|'.join(map(re.escape, dict.keys()))), lambda m: dict[m.group()], kana)

def convert_kata2hira(kata):
    return jaconv.kata2hira(kata)

def make_word_chunk_form(arg_dict):
    chunk_form = []
    common_words = get_common_words()
    for d in arg_dict:
        word = d
        familiarity = arg_dict[d]
        base_level = float(familiarity) * 100 #ここの計算をどうするか，ベースレベルの効き方で決める？##正規化したいね
        if word in common_words:
            base_level += 300
        chunk_form.append("(" + word + " " + str(base_level) + " -100)") #(チャンク名 ベースレベル チャンク生成からの時間) -100はテキトー
    return chunk_form

def export_base_level(chunks, e_path):
    with open(e_path, mode="w") as e_file:
        e_file.write(";;Created by wc/scripts/make_base_levels.py \n")
        e_file.write("(defvar *word-base-levels*)\n")
        e_file.write("(setf *word-base-levels* '(\n")
        for chunk in chunks:
            e_file.write("  " + chunk + "\n")
        e_file.write("))")

def make_base_levels():
    path = "./D_Data.csv"
    word_dict = select_noun(path)
    word_dict = replace_v(word_dict)
    word_dict = replace_l(word_dict)
    #辞書使ってるのでもうユニーク
    #ただし↑の処理で例えばバイオリンの後にヴァイオリンが出現した場合その親密度で上書きされている可能性がある．同一の値ならいいが
    #word_list = unique_list(word_list)

    #モーラに関する処理は今回必要なし
    #wwm_list = make_list_wwm(word_list)

    word_dict = convert_kata2alpha(word_dict)

    base_levels = make_word_chunk_form(word_dict)
    bl_path = "./wc-base-levels.lisp"
    export_base_level(base_levels, bl_path)

    print(base_levels)

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

def c_words_convert(words):
    mydict = make_kana_alpha_dict()
    mydict = dict(sorted(mydict.items(), reverse=True, key=lambda x : len(x[0])))
    res = []

    for i in words:
        #小文字と表記揺れを削除
        word = i.replace("デュ","デユ").replace("ヴァ","バ").replace("ヴィ","ビ").replace("ヴ","ブ").replace("ヂ","ジ").replace("ヅ","ズ")
        word = word.replace("ァ","ア").replace("ィ","イ").replace("ゥ","ウ").replace("ェ","エ").replace("ォ","オ").replace("ヮ","ワ")

        #アルファベット変換
        word = my_sub(mydict, word)
        res.append(word)
    return res



def get_common_words():
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

        return c_words_convert(tmp)

make_base_levels()
    

