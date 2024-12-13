import re
import jaconv

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
    replaced_data = [d.replace("デュ","デユ").replace("ヴァ","バ").replace("ヴィ","ビ").replace("ヴ","ブ").replace("ヂ","ジ").replace("ヅ","ズ") for d in data]
    return replaced_data

def replace_l(data):
    replaced_data = [d.replace("ァ","ア").replace("ィ","イ").replace("ゥ","ウ").replace("ェ","エ").replace("ォ","オ").replace("ヮ","ワ") for d in data]
    return replaced_data

def unique_list(word_list):
    return sorted(set(word_list), key=word_list.index)

#def convert_kata2hira(kata_list):
#    return [jaconv.kata2hira(kata) for kata in kata_list]
def convert_kata2hira(kata):
    return jaconv.kata2hira(kata)

def make_dict_hira_mora(word_list):
    word_mora_dict = {}
    for word in word_list:
        mora_lst = re.sub(",(ャ|ュ|ョ)", "\\1", ",".join(word))
        if len(word) > 1:
            word_mora_dict[convert_kata2hira(word)] = mora_lst
    return word_mora_dict

def make_list_wwm(word_list):
    word_word_mora_list = []
    for word in word_list:
        mora_lst = re.sub(",(ャ|ュ|ョ)", "\\1", ",".join(word))
        if len(word) > 1:
            word_word_mora_list.append([convert_kata2hira(word), word, mora_lst])
    return word_word_mora_list

def remove_tail_long(wwm_list):
    result = []
    for wwm in wwm_list:
        if wwm[2][-1] == "ー": #["こんぴゅーたー","コンピューター","コ,ン,ピュ,ー,タ,ー"]
            result.append([wwm[0], wwm[1], wwm[2][:-2]]) #remove ",ー"
        else:
            result.append([wwm[0], wwm[1], wwm[2]])
    return result

def replace_tail_long2vowel(wwm_list):
    result = []
    for wwm in wwm_list:
        if wwm[2][-1] == "1":
            result.append([wwm[0], wwm[1], (wwm[2][:-1] + [wwm[2][-2][-1]])]) #replace "ko","0","pju","1","ta","1" -> "ko","0","pju","1","ta","a"
        else:
            result.append([wwm[0], wwm[1], wwm[2]]) 
    return result

def my_sub(dict, kana):
    return re.sub('({})'.format('|'.join(map(re.escape, dict.keys()))), lambda m: dict[m.group()], kana)

def convert_kata2alpha(wwm_list):
    mydict = make_kana_alpha_dict()
    mydict = dict(sorted(mydict.items(), reverse=True, key=lambda x : len(x[0])))
    #alpha_list = {my_sub(mydict, i): my_sub(mydict, word_mora_dic[i]).split(",") for i in word_mora_dic}
    #alpha_list = {i: my_sub(mydict, word_mora_dict[i]).split(",") for i in word_mora_dict}
    result = []
    for wwm in wwm_list:
        result.append([wwm[0], my_sub(mydict, wwm[1]), my_sub(mydict, wwm[2]).split(",")])

    return result

def drop_len1_word(wwm_list):
    result = []
    for wwm in wwm_list:
        if len(wwm[2]) > 1:
            result.append(wwm)
    return result

def make_wm_chunk_form(wm_dict):
    chunk_form = []
    for hira in wm_dict:
        for i in range(len(wm_dict[hira])):
            mora = wm_dict[hira][i]
            word = "".join(wm_dict[hira])
            head_posi = str(i)
            tail_posi = str((len(wm_dict[hira])-1) - i)
            chunk_form.append("(word-mora-" + word + "-" + mora + "-" + head_posi + "-" + tail_posi + " ISA word-mora wm-word " + word + " wm-mora " + mora + " head-posi " + head_posi + " tail-posi " + tail_posi + ")")
    return chunk_form

def make_wm_chunk_form_00(wwm_list):
    chunk_form = []
    for wwm in wwm_list:
        head = wwm[2][0]
        tail = wwm[2][-1]
        word = wwm[1]
        other_side_posi = str(len(wwm[2]) - 1)
        #head
        chunk_form.append("(word-mora-" + word + "-" + head + "-0-" + other_side_posi + " ISA word-mora wm-word " + word + " wm-mora " + head + " head-posi 0 tail-posi " + other_side_posi + ")")
        #tail
        chunk_form.append("(word-mora-" + word + "-" + tail + "-" + other_side_posi + "-0 ISA word-mora wm-word " + word + " wm-mora " + tail + " head-posi " + other_side_posi + " tail-posi 0)")
    return chunk_form

def make_word_chunk_form(wwm_list):
    chunk_form = []
    for wwm in wwm_list:
        hira = wwm[0]
        word = wwm[1]
        chunk_form.append("(" + word + " ISA word word-concept " + word + " word-sound \"" + hira + "\")")
        #print("(word-mora-" + word + "-" + mora + " ISA word-mora word " + word + " mora " + mora + " pos-head " + str(i) + " pos-tail " + str((len(data[word])-1) - i) + ")")
    return chunk_form

def make_mora_chunk_form():
    mora_dict = make_kana_alpha_dict()
    chunk_form = []
    for kata in mora_dict:
        mora = mora_dict[kata]
        chunk_form.append("(" + mora + "-mora ISA mora mora-concept " + mora + " mora-sound \"" + convert_kata2hira(kata) + "\")")
        #print("(word-mora-" + word + "-" + mora + " ISA word-mora word " + word + " mora " + mora + " pos-head " + str(i) + " pos-tail " + str((len(data[word])-1) - i) + ")")
    return chunk_form

def export_chunk(chunks, var_name, e_path):
    with open(e_path, mode="w") as e_file:
        e_file.write("(defvar *" + var_name + "*)\n")
        e_file.write("(setf *" + var_name + "* '(\n")
        for chunk in chunks:
            e_file.write("  " + chunk + "\n")
        e_file.write("))")


def make_basic_chunks():
    path = "./D_Data.csv"
    word_list = select_noun(path)
    word_list = replace_v(word_list)
    word_list = replace_l(word_list)

    word_mora_dict = make_dict_hira_mora(word_list)
    print(word_mora_dict)
    word_mora_dict = convert_kata2alpha(word_mora_dict)

    wm_chunks = make_wm_chunk_form(word_mora_dict)
    wm_path = "./word-mora.lisp"
    export_chunk(wm_chunks, "wm-list", wm_path)
    
    word_chunks = make_word_chunk_form(word_mora_dict)
    word_path = "./word.lisp"
    export_chunk(word_chunks, "word-list", word_path)

    mora_chunks = make_mora_chunk_form()
    mora_path = "./mora.lisp"
    export_chunk(mora_chunks, "mora-list", mora_path)

def make_chunks_only_wm00():
    path = "./D_Data.csv"
    word_list = select_noun(path)
    word_list = replace_v(word_list)
    word_list = replace_l(word_list)

    word_mora_dict = make_dict_hira_mora(word_list)
    word_mora_dict = convert_kata2alpha(word_mora_dict)

    wm_chunks = make_wm_chunk_form_00(word_mora_dict)
    wm_path = "./word-mora-00.lisp"
    export_chunk(wm_chunks, "wm-list", wm_path)
    
    word_chunks = make_word_chunk_form(word_mora_dict)
    word_path = "./word.lisp"
    export_chunk(word_chunks, "word-list", word_path)

    mora_chunks = make_mora_chunk_form()
    mora_path = "./mora.lisp"
    export_chunk(mora_chunks, "mora-list", mora_path)

def make_chunks_without_tail_long():
    path = "./D_Data.csv"
    word_list = select_noun(path)
    word_list = replace_v(word_list)
    word_list = replace_l(word_list)
    word_list = unique_list(word_list)

    #word_mora_dict = make_dict_hira_mora(word_list)
    wwm_list = make_list_wwm(word_list)
    wwm_list = remove_tail_long(wwm_list)
    wwm_list = convert_kata2alpha(wwm_list)
    #wwm_list = drop_len1_word(wwm_list)    #他のモデルと語彙数が異なる可能性があるのは良くなさそうword-mora-0-0というチャンクがあっても困らない？
    
    wm_chunks = make_wm_chunk_form_00(wwm_list)
    wm_path = "./word-mora-wo-tl.lisp"
    export_chunk(wm_chunks, "wm-list-wo-tl", wm_path)
    
    word_chunks = make_word_chunk_form(wwm_list)
    word_path = "./word-wo-tl.lisp"
    export_chunk(word_chunks, "word-list-wo-tl", word_path)

    mora_chunks = make_mora_chunk_form()
    mora_path = "./mora.lisp"
    export_chunk(mora_chunks, "mora-list", mora_path)

def make_chunks_tail_long_to_vowel():
    path = "./D_Data.csv"
    word_list = select_noun(path)
    print(len(word_list))
    word_list = replace_v(word_list)
    print(len(word_list))
    word_list = replace_l(word_list)
    print(len(word_list))
    word_list = unique_list(word_list)
    print(len(word_list))

    wwm_list = make_list_wwm(word_list)
    print(len(wwm_list))
    wwm_list = convert_kata2alpha(wwm_list)
    print(len(wwm_list))
    wwm_list = replace_tail_long2vowel(wwm_list)
    print(len(wwm_list))
    #wwm_list = drop_len1_word(wwm_list)        #他のモデルと語彙数が異なる可能性があるのは良くなさそうword-mora-0-0というチャンクがあっても困らない？

    wm_chunks = make_wm_chunk_form_00(wwm_list)
    print(len(wm_chunks))
    wm_path = "./word-mora-tl2v.lisp"
    export_chunk(wm_chunks, "wm-list-tl2v", wm_path)
    
    word_chunks = make_word_chunk_form(wwm_list)
    word_path = "./word-tl2v.lisp"
    export_chunk(word_chunks, "word-list-tl2v", word_path)

    mora_chunks = make_mora_chunk_form()
    mora_path = "./mora.lisp"
    export_chunk(mora_chunks, "mora-list", mora_path)

def make_words_file():
    print("aaa")


def test():
    path = "./D_Data.csv"
    word_list = select_noun(path)
    word_list = replace_v(word_list)
    word_list = replace_l(word_list)
    #これだめ．ひらがなは"こんぴゅーたー"などのままにしたい
    #word_list = remove_tail_long(word_list) ##This makes chunks "without tail long"

    #word_mora_dict = make_dict_hira_mora(word_list)
    wwm_list = make_list_wwm(word_list)
    wwm_list = convert_kata2alpha(wwm_list)
    wwm_list = replace_tail_long2vowel(wwm_list)
    
    wm_chunks = make_wm_chunk_form_00(wwm_list)
    print(wm_chunks)


if __name__ == "__main__":
    #make_basic_chunks()
    #make_chunks_only_wm00()
    make_chunks_without_tail_long()
    make_chunks_tail_long_to_vowel()

    #test()

