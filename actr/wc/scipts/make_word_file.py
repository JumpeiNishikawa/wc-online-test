import jaconv


def convert_kata2hira(kata):
    return jaconv.kata2hira(kata)
def replace_v(data):
    replaced_data = [d.replace("デュ","デユ").replace("ヴァ","バ").replace("ヴィ","ビ").replace("ヴ","ブ").replace("ヂ","ジ").replace("ヅ","ズ") for d in data]
    return replaced_data

def replace_l(data):
    replaced_data = [d.replace("ァ","ア").replace("ィ","イ").replace("ゥ","ウ").replace("ェ","エ").replace("ォ","オ").replace("ヮ","ワ") for d in data]
    return replaced_data

def main():
    path = "./D_Data.csv"
    e_path = "words.txt"
    with open(path) as file, open(e_path, mode="w") as e_file:
        data = file.readlines()
        word_list = []

        for d in data:
            d = d.split(",")
            if not d[8].find("名") == -1:
                word_list.append(d[4])
        #unique
        word_list = sorted(set(word_list), key=word_list.index)
        #表記揺れの統一
        word_list = replace_v(word_list)
        word_list = replace_l(word_list)

        for w in word_list:
            if len(w) > 1:
                e_file.write(convert_kata2hira(w) + "\n")



if __name__ == "__main__":
    main()