if __name__ == "__main__":
    words = {}
    count = 0
    o = open('outfile.txt', 'w')
    z = open('outfileMeta.txt', 'w')
    f = open('data.txt', 'r')

    for line in f:
        if not line.strip():
            break
        basket = line.split(',')
        basket[-1] = basket[-1][:-1]
        for item in basket:

            if item not in words.keys():
                words[item] = count
                count += 1
            o.write(str(words[item]) + " ")
        o.write("\n")

    for k, v in words.items():
        z.write( str(v) + ": " + str(k) + "\n")
    print("Total unique names: ", count)