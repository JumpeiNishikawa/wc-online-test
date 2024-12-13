with open("./w_m.txt") as file, open("./word_mora00.lisp", mode="a") as result_file:
    line = file.readline()
    result_file.write("(add-dm\n")
    while line:
        l = line.split(" ")
        if "-0" in l[0]:
            #print(line)
            result_file.write("  " + line)
            #outfile.write(line)
        line = file.readline()
    result_file.write(")\n")