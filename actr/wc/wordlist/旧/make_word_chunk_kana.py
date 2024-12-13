import re

def make_kana_alpha_dict():
    alpha = "a,i,u,e,o,ja,ju,jo,ka,ki,ku,ke,ko,kja,kju,kjo,ga,gi,gu,ge,go,gja,gju,gjo,sa,si,su,se,so,sja,sju,sjo,za,zi,zu,ze,zo,zja,zju,zjo,ta,ti,tu,te,to,tja,tju,tjo,da,de,do,na,ni,nu,ne,no,nja,nju,njo,ha,hi,hu,he,ho,hja,hju,hjo,pa,pi,pu,pe,po,pja,pju,pjo,ba,bi,bu,be,bo,bja,bju,bjo,ma,mi,mu,me,mo,mja,mju,mjo,ra,ri,ru,re,ro,rja,rju,rjo,wa,N,R,Q"
    kana = "ア,イ,ウ,エ,オ,ヤ,ユ,ヨ,カ,キ,ク,ケ,コ,キャ,キュ,キョ,ガ,ギ,グ,ゲ,ゴ,ギャ,ギュ,ギョ,サ,シ,ス,セ,ソ,シャ,シュ,ショ,ザ,ジ,ズ,ゼ,ゾ,ジャ,ジュ,ジョ,タ,チ,ツ,テ,ト,チャ,チュ,チョ,ダ,デ,ド,ナ,ニ,ヌ,ネ,ノ,ニャ,ニュ,ニョ,ハ,ヒ,フ,ヘ,ホ,ヒャ,ヒュ,ヒョ,パ,ピ,プ,ペ,ポ,ピャ,ピュ,ピョ,バ,ビ,ブ,ベ,ボ,ビャ,ビュ,ビョ,マ,ミ,ム,メ,モ,ミャ,ミュ,ミョ,ラ,リ,ル,レ,ロ,リャ,リュ,リョ,ワ,ン,ー,ッ"

    #ui,ue,uo,sie,jie,tie,tei,dei,hua,hui,hue,huo,tua
    #ウィ,ウェ,ウォ,シェ,ジェ,チェ,ティ,ディ,ファ,フィ,フェ,フォ,ツァ,
    alpha_list = alpha.split(",")
    kana_list = kana.split(",")

    kana_alpha_dict = dict(zip(kana_list, alpha_list))

    #print(kana_alpha_dict)
    return kana_alpha_dict

def select_noun(path):
    print("select_noun")
    with open(path) as raw_data:
        lines = raw_data.readlines()
        noun_list = []
        for line in lines:
            linelst = line.split(",")
            if not linelst[8].find("名") == -1:
                #print(linelst[4] + "," + linelst[8])
                noun_list.append(linelst[4])

        return noun_list

def replace_v(data):
    #data = select_noun()

    replaced_data = [d.replace("デュ","デユ").replace("ヴァ","バ").replace("ヴィ","ビ").replace("ヴ","ブ").replace("ヂ","ジ").replace("ヅ","ズ") for d in data]

    #print(replaced_data)
    return replaced_data

def replace_l(data):
    #data = replace_v()

    replaced_data = [d.replace("ァ","ア").replace("ィ","イ").replace("ゥ","ウ").replace("ェ","エ").replace("ォ","オ").replace("ヮ","ワ") for d in data]

    #print(replaced_data)
    return replaced_data

def remove_tail_long(data):
    #data = replace_l()

    replaced_data = [d[:-1] if d[-1] == "ー" else d for d in data]

    return replaced_data

def split_mora(data):
    #data = remove_tail_long()
    word_mora_dict = {}

    for word in data:
        mora_lst = re.sub(",(ャ|ュ|ョ)", "\\1", ",".join(word))
        if len(word) > 1:
            word_mora_dict[word] = mora_lst
    
    return word_mora_dict

def my_sub(dict, kana):
    return re.sub('({})'.format('|'.join(map(re.escape, dict.keys()))), lambda m: dict[m.group()], kana)

def Convert_kana_alpha(data):
    #ka_dict = make_kana_alpha_dict()
    #data = split_mora()

    mydict = make_kana_alpha_dict()
    mydict = dict(sorted(mydict.items(), reverse=True, key=lambda x : len(x[0])))

    res = {my_sub(mydict, i): my_sub(mydict, data[i]).split(",") for i in data}
    #result = re.sub('({})'.format('|'.join(map(re.escape, sorted_ka_dict.keys()))), lambda m: sorted_ka_dict[m.group()], d)
    #print(result)

    return res

def make_word_chunk_form(data):
    #data = Convert_kana_alpha()
    #(word-mora-riNgo-ri ISA word-mora word rinNgo mora ri pos-head 0 pos-tail 2)
    chunk_form = []
    for word in data:
        for i in range(len(data[word])):
            mora = data[word][i]
            pos_head = str(i)
            pos_tail = str((len(data[word])-1) - i)
            chunk_form.append("(word-mora-" + word + "-" + mora + "-" + pos_head + "-" + pos_tail + " ISA word-mora wm-word " + word + " mora " + mora + " pos-head " + pos_head + " pos-tail " + pos_tail + ")")
            #print("(word-mora-" + word + "-" + mora + " ISA word-mora word " + word + " mora " + mora + " pos-head " + str(i) + " pos-tail " + str((len(data[word])-1) - i) + ")")
    return chunk_form

def export_chunk_file():
    path = "./旧/D_Data.csv"
    #data = make_word_chunk_form(path)
    word_list = select_noun(path)
    word_list = replace_v(word_list)
    word_list = replace_l(word_list)
    word_list = remove_tail_long(word_list)
    print(word_list)

    word_list = split_mora(word_list)
    word_list = Convert_kana_alpha(word_list)
    word_list = make_word_chunk_form(word_list)

    r_path = "./word2.lisp"

    with open(r_path, mode="a") as result_file:
        result_file.write("(add-dm\n")
        for i in word_list:
            result_file.write("  " + i + "\n")
        result_file.write(")")

export_chunk_file()