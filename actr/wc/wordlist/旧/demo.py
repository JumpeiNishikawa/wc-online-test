with open("./word.lisp") as file:
    data = file.readlines()
    for i in range(len(data)):
        if i % 200 == 2:
            print(data[i])