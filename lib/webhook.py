# Copyright (c) 2022 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# pip3 install flask

from flask import Flask, request, json

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Webhooks with Python'

@app.route('/webhook')
def webhook():
    print(request.get_data().decode('utf-8'))


if __name__ == '__main__':
    app.run(debug=True)