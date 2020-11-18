from flask import Flask, request
import numpy as np
import pytesseract
import re
import cv2
import sys
import json
from json import JSONEncoder
from urllib.request import urlopen
import itertools
import copy

app = Flask(__name__)

class NumpyArrayEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return JSONEncoder.default(self, obj)


@app.route('/array',methods=['POST'])
def get():
    if request.method == 'POST':
        url = request.args.get(key='imagelink')
        req = urlopen(url)
        arr = np.asarray(bytearray(req.read()), dtype=np.uint8)
        img = cv2.imdecode(arr, -1) # 'Load it as it is'

        # Load image
        original = img.copy()  # Original Image copy
        # Image Processing
        gamma = 0.8
        invGamma = 1/gamma
        table = np.array([((i / 255.0) ** invGamma) * 255
                        for i in np.arange(0, 256)]).astype("uint8")
        cv2.LUT(img, table, img)
        img = cv2.fastNlMeansDenoisingColored(img,None,10,10,7,21)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) #To grayscale
        img = cv2.adaptiveThreshold(img,255, cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY, 11, 12) #To binary
        img = np.invert(img) #Invert
        img = cv2.morphologyEx(img, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_RECT,(3,3))) #Closing
        contours,hier = cv2.findContours(img,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE) #Find all contours
        biggest_area = 0
        biggest_contour = None
        for i in contours:
            area = cv2.contourArea(i)
            if area > biggest_area:
                biggest_area = area
                biggest_contour = i
        if biggest_contour is None:
            sys.exit(1)
        mask = np.zeros((img.shape),np.uint8)
        cv2.drawContours(mask, [biggest_contour], 0, (255,255,255), -1)
        img = cv2.bitwise_and(img, mask)
        

        grid = original.copy()
        cv2.drawContours(grid, [biggest_contour], 0, (255,0,255), 3)
        contours,hier = cv2.findContours(img,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE) #Find all contours
        
        c = 0
        grid = original.copy()
        average_cell_size = biggest_area/81
        bound_range = 4
        lower_bound = average_cell_size - average_cell_size/bound_range
        upper_bound = biggest_area/81 + average_cell_size/bound_range
        cells = []
        x,y,w,h = cv2.boundingRect(biggest_contour)
        epsilon = 0.1*cv2.arcLength(biggest_contour,True)
        approx = cv2.approxPolyDP(biggest_contour,epsilon,True)
        cv2.drawContours(grid, [approx], 0, (255,255,0), 3)
        for i in contours:
            area = cv2.contourArea(i)
            if area >= lower_bound and area <= upper_bound:
                cv2.drawContours(grid, contours, c, (0, 255, 0), 3)
                cells.append(i) 
            c+=1
        
        
        bx,by,bw,bh = cv2.boundingRect(biggest_contour)
        aw = int(bw/9)
        ah = int(bh/9)
        awb = int(aw/4)
        ahb = int(aw/4)
        tabla= np.zeros((9,9))
        dataList = []
        if len(cells) == 81:
            for i in range(9):
                for j in range(9):
                    x = [0, int(bx-awb+j*aw), int(bx+bw)]
                    y = [0, int(by-ahb+i*ah), int(by+bh)]
                    x.sort()
                    y.sort()
                    x = x[1]
                    y = y[1]
                    crop = img[y:by+ah+ahb+i*ah, x:bx+aw+awb+j*aw]
                    cont,hier = cv2.findContours(crop,cv2.RETR_TREE,cv2.CHAIN_APPROX_SIMPLE)
                    bsize = 0
                    bcont = None
                    bindex = None
                    for c in range(len(cont)):
                        area = cv2.contourArea(cont[c])
                        if area > bsize:
                            bsize = area
                            bcont = cont[c]
                            bindex = c
                    if bcont is None:
                        sys.exit(1)
                    else:
                        secondbsize = 0
                        secondbcont = None
                        for c in range(len(cont)):
                            if hier[0][c][3] == bindex:
                                area = cv2.contourArea(cont[c])
                                if area > secondbsize:
                                    secondbsize = area
                                    secondbcont = cont[c]
                        if secondbcont is None:
                            sys.exit(2)
                        mask = np.zeros((crop.shape),np.uint8)
                        cv2.drawContours(mask, [secondbcont], 0, (255,255,255), -1)
                        finetune = cv2.bitwise_and(crop, mask)
                        x,y,w,h = cv2.boundingRect(secondbcont)
                        finetune = finetune[y+3:y+h-3,x+3:x+w-3]
                        finetune = cv2.morphologyEx(finetune, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_RECT,(3,3)))
                        finetune = np.invert(finetune)
                        kernel = np.array([[-1,-1,-1], [-1,9,-1], [-1,-1,-1]])
                        finetune = cv2.filter2D(finetune, -1, kernel)
                        finetune = cv2.resize(finetune,(0,0),fx=3,fy=3)
                        finetune = cv2.GaussianBlur(finetune,(11,11),0)
                        finetune = cv2.medianBlur(finetune,9)
                        data = pytesseract.image_to_string(finetune, lang='eng',config='--psm 10 --oem 3 -c tessedit_char_whitelist=123456789')
                        dataList = dataList + re.split(r',|\.|\n| ',data)
                        number = re.findall('\d+',data)
                        if not re.findall('\d+',data):
                            tabla[i,j] = 0  
                        else:
                            tabla[i,j] = number[0]
                
        else:
            sys.exit(1)

       
        numpyData = {"array": tabla}
        encodedNumpyData = json.dumps(numpyData, cls=NumpyArrayEncoder)
        return encodedNumpyData
@app.route('/solveAll',methods=['POST'])
def solveAll():
    if request.method == 'POST':
        array = request.args.get(key='array')
        table = createSudoku(array)
        table2 = np.zeros((9,9))
        arrayBacktracked = backtrack(table)
        invInt = invertedIntersection(arrayBacktracked, table)
        for i in range(9):
          for j in range(9):
            if invInt[i,j] != 0:
              table2[i,j] = invInt[i,j]
            break
          break
        response = {"array": arrayBacktracked }
        encodedNumpyData = json.dumps(response, cls=NumpyArrayEncoder)
        return encodedNumpyData
@app.route('/hint',methods=['POST'])
def giveHint():
    if request.method == 'POST':
      array = request.args.get(key='array')
      table = createSudoku(array)
      backtrackedTable = backtrack(table)
      invInt = invertedIntersection(backtrackedTable, table)
      for i in range(9):
        for j in range(9):
          if invInt[i,j] != 0:
            table[i,j] = invInt[i,j]
            break
        break
      response = {"array":table }
      encodedNumpyData = json.dumps(response, cls=NumpyArrayEncoder)
      return encodedNumpyData
def invertedIntersection(A, B) :
  tabla = np.zeros((9,9))
  for i in range(9) : 
    for j in range(9) : 
      if (A[i,j] != B[i,j]) : 
        tabla[i,j] = A[i,j]
      else : 
        tabla[i,j] = 0
  return tabla
def createSudoku(array):
  array = array.replace('[','')
  array = array.replace(']','')
  sudoku = array.split(',')
  sudokuint = [int(numeric_string) for numeric_string in sudoku]
  table = np.zeros((9,9))
  cont = 0
  for i in range (9):
    for j in range (9):
      table[i,j] = sudokuint[cont]
      cont = cont +1
  return table  
def check_sudoku(grid):
  bad_rows = [row for row in grid if not sudoku_ok(row)]
  grid = list(zip(*grid))
  bad_cols = [col for col in grid if not sudoku_ok(col)]
  squares = []
  for i in range(0,9,3):
      for j in range(0,9,3):
        square = list(itertools.chain.from_iterable([i for i in (row[j:j+3] for row in grid[i:i+3])]))
        squares.append(square)
  bad_squares = [square for square in squares if not sudoku_ok(square)]
  return not (bad_rows or bad_cols or bad_squares)
def sudoku_ok(line):
  for x in range(len(line)):
    for y in range(x+1, len(line)):
      if line[x] == line[y] and not line[x] == 0:
        return False
  return True
def backtrack(board):
  if not check_sudoku(board):
    return None
  if board_full(board):
    return board
  i,j = find_index(board)
  if i is not None:
    for x in range(9):
      boardchecking = copy.deepcopy(board)
      boardchecking[i][j] = x+1
      found = backtrack(boardchecking)
      if found is not None:
        return found
    return None
def find_index(board):
  for i in range(9):
    for j in range(9):
      if board[i][j]==0:
        return i,j
  return None, None
def board_full(board):
  for i in range(9):
    for j in range(9):
      if board[i][j]==0:
        return False
  return True

if __name__ == '__main__':
    app.run(debug=True,host= "192.168.1.4", port= 4000)