import collections
import numpy as np


def readStopWords(filename, stopList):
    f = open(filename)
    for line in f:
        line = line.replace("\n", "")
        stopList[line] = True
    f.close()


def readDataAndProcess(filenameData, filenameLables, filenameTestData, filenameTestLabels, testData, testDataMapper, testDataLables, stopWords, testDataCookie, testDataCookieLabels):
    testDataList = []

    f = open(filenameData)
    for line in f:
        line = line.replace("\n", "")
        for word in line.split(" "):
            if word not in stopWords.keys():
                testDataMapper[word] = 0
    f.close()
    f = open(filenameTestData)
    for line in f:
        line = line.replace("\n", "")
        for word in line.split(" "):
            if word not in stopWords.keys():
                testDataMapper[word] = 0
    f.close()

    for key in testDataMapper.keys():
        testDataList.append(key)
    testDataList.sort()

    for i in range(0, len(testDataList)):
        testDataMapper[testDataList[i]] = i

    f = open(filenameData)
    for line in f:
        line = line.replace("\n", "")
        tempLine = [0 for i in range(0, len(testDataList))]
        for word in line.split(" "):
            if word not in stopWords.keys():
                tempLine[testDataMapper[word]] += 1
        testData.append(tempLine)
    f.close()

    f = open(filenameLables)
    for line in f:
        line = line.replace("\n", "")
        testDataLables.append(int(line))

    f = open(filenameTestData)
    for line in f:
        line = line.replace("\n", "")
        tempLine = [0 for i in range(0, len(testDataList))]
        for word in line.split(" "):
            if word not in stopWords.keys():
                tempLine[testDataMapper[word]] += 1
        testDataCookie.append(tempLine)
    f.close()

    f = open(filenameTestLabels)
    for line in f:
        line = line.replace("\n", "")
        testDataCookieLabels.append(int(line))

def cookieClassifierTest(testData, testingDataLables, weight):
    failed = 0
    for trainingRow in range(0, len(testData)):
        dot = np.sum(np.dot(np.array(testData[trainingRow]), weight))
        expected = testingDataLables[trainingRow]
        predicted = 0
        if dot >= 0:
            predicted = 1
        if expected != predicted:
            failed += 1
    print("Testing: ", len(testData)-failed, " / ", len(testData), ":" , (len(testData)-failed)/len(testData), "\n")


def cookieClassifier(trainingData, trainingDataLabels, testData, testDataLabels):
    print("Starting Cookie Classifier")
    weight = np.array([0 for i in range(0, len(trainingData[0]))])
    for i in range(0, 20):  # 10 iterations
        failed = 0
        for trainingRow in range(0, len(trainingData)):
            dot = np.sum(np.dot(np.array(trainingData[trainingRow]), weight))
            expected = trainingDataLabels[trainingRow]
            predicted = 0
            if dot >= 0:
                predicted = 1
            if expected != predicted:
                failed += 1
                weight = [weight[i] + 1 * (expected - predicted) * trainingData[trainingRow][i] for i in
                          range(0, len(trainingData[0]))]
        print("Run ", i+1, ": ", (len(trainingData)-failed), " / ", len(trainingData), (len(trainingData)-failed) / len(trainingData))
        cookieClassifierTest(testData, testDataLabels, weight)
    return weight


def cookieClassifierAvgTest(testData, testDataLabels, avgWeights):
    failed = 0
    for trainingRow in range(0, len(testData)):
        dotsum = np.sum(np.dot(testData[trainingRow], avgWeights))
        expected = testDataLabels[trainingRow]
        predicted = 0
        if dotsum >= 0:
            predicted = 1
        if expected != predicted:
            failed += 1
    print("Test: ", (len(testData)-failed), " / ", len(testData), (len(testData)-failed)/len(testData), "\n")


def cookieClassifierAvg(trainingData, trainingDataLabels, testData, testDataLabels):
    print("Starting Cookie Classifier Avg")
    weight = np.array([0.0 for i in range(0, len(trainingData[0]))])

    avgWeights = [0, np.array([0.0 for i in range(0, len(trainingData[0]))])]
    for i in range(0, 20):  # 10 iterations
        failed = 0
        run = 1
        for trainingRow in range(0, len(trainingData)):
            dotsum = np.sum(np.dot(trainingData[trainingRow], avgWeights[1]))
            expected = trainingDataLabels[trainingRow]
            predicted = 0
            if dotsum >= 0:
                run += 1
                predicted = 1
            if expected != predicted:
                failed += 1
                total = avgWeights[0] + run
                multiplier = run/total
                demultiplier = (total-run)/total
                weight *= multiplier
                avgWeights[1] *= demultiplier
                avgWeights[1] += weight
                avgWeights[0] += run
                run = 1
                weight = np.array([weight[i] + 1 * (expected - predicted) * trainingData[trainingRow][i] for i in
                          range(0, len(trainingData[0]))])
        print("Run ", i+1, ": ", len(trainingData)-failed, " / ",len(trainingData), (len(trainingData)-failed)/len(trainingData))
        cookieClassifierAvgTest(testData, testDataLabels, avgWeights[1])
    return weight


def OCRAvg(trainingData, trainingDataLabels, testingData, testingDataLabels):
    print("Starting OCR Avg")
    weights = np.array([[0.0 for i in range(0, len(trainingData[0]))] for j in range(0, 26)])
    avgWeights = np.array([1, np.array([[0.0 for i in range(0, len(trainingData[0]))] for j in range(0, 26)])])
    for iteration in range(0, 20):
        failed = 0
        run = 1
        for row in range(0, len(trainingData)):
            dotProducts = [np.sum(np.dot(trainingData[row], avgWeights[1][i])) for i in range(0, len(avgWeights[1]))]
            predicted = np.argmax(dotProducts)
            expected = trainingDataLabels[row]
            if expected != predicted:
                failed += 1
                total = avgWeights[0] + run
                multiplier = run / total
                demultiplier = (total - run) / total
                weights *= multiplier
                avgWeights[1] *= demultiplier
                avgWeights[1] += weights
                avgWeights[0] += run
                run = 1
                weights[predicted] -= trainingData[row]
                weights[expected] += trainingData[row]

        print("Run", iteration+1, ":", (len(trainingData) - failed), "/", len(trainingData))
        OCRTest(testingData, testingDataLabels, avgWeights[1])
    return weights


def OCRTest(testingData, testingDataLabels, weights):
    failed = 0
    for row in range(0, len(testingData)):
        dotProducts = [np.sum(np.dot(testingData[row], weights[i])) for i in range(0, len(weights))]
        predicted = np.argmax(dotProducts)
        expected = testingDataLabels[row]
        if expected != predicted:
            failed += 1
    print("Testing:", (len(testingData) - failed), "/", len(testingData), (len(testingData) - failed) / len(testingData),"\n")


def OCR(trainingData, trainingDataLabels, testingData, testingDataLabels):
    print("Starting OCR")
    weights = np.array([[0 for i in range(0, len(trainingData[0]))] for j in range(0, 26)])
    for iteration in range(0, 20):
        failed = 0
        for row in range(0, len(trainingData)):
            dotProducts = [np.sum(np.dot(trainingData[row], weights[i])) for i in range(0, len(weights))]
            predicted = np.argmax(dotProducts)
            expected = trainingDataLabels[row]
            if expected != predicted:
                failed += 1
                weights[predicted] -= trainingData[row]
                weights[expected] += trainingData[row]

        print("Run", iteration+1, ":", len(trainingData)-failed, "/", len(trainingData), (len(trainingData)-failed)/len(trainingData))
        OCRTest(testingData, testingDataLabels, weights)
    return weights




def getOCRgData(filename, dataArr, expectedArr):
    f = open(filename)
    for line in f:
        line = line.replace("\n", "")
        line = line.replace("im", "")
        line = line.split("\t")
        if line[1] is not '':
            tempLine = []
            for char in line[1]:
                tempLine.append(int(char))
            dataArr.append(tempLine)
            expectedArr.append(ord(line[2]) - ord('a'))


if __name__ == '__main__':
    ocrTrainingData = []
    ocrTrainingDataLables = []
    ocrTestingData = []
    ocrTestingDataLabels = []
    trainingDataCookie = []
    trainingDataCookieLabels = []
    testDataCookie = []
    testDataCookieLabels = []
    testDataCookieMapper = {}
    getOCRgData("ocr_train.txt", ocrTrainingData, ocrTrainingDataLables)
    getOCRgData("ocr_test.txt", ocrTestingData, ocrTestingDataLabels)


    stopListCookie = {}
    trainingDataCookieMapper = collections.defaultdict(int)


    readStopWords("stoplist.txt", stopListCookie)
    readDataAndProcess("traindata.txt", "trainlabels.txt", "testdata.txt", "testlabels.txt", trainingDataCookie, trainingDataCookieMapper, trainingDataCookieLabels,
                       stopListCookie,testDataCookie, testDataCookieLabels)


    # weights = cookieClassifierAvg(np.array(trainingDataCookie), np.array(trainingDataCookieLabels), np.array(testDataCookie), np.array(testDataCookieLabels))
    # weights = cookieClassifier(np.array(trainingDataCookie), np.array(trainingDataCookieLabels), np.array(testDataCookie), np.array(testDataCookieLabels))

    OCRAvg(np.array(ocrTrainingData), np.array(ocrTrainingDataLables),np.array(ocrTestingData), np.array(ocrTestingDataLabels))
    OCR(np.array(ocrTrainingData), np.array(ocrTrainingDataLables),np.array(ocrTestingData), np.array(ocrTestingDataLabels))
    #print(stopListCookie)
