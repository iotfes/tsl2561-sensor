# coding: utf-8
#----------------------------------------------------------------------
# tsl2561.rb
# TSL2561照度センサから照度を取得し、Cumulocityへアップするスクリプト
# usage: $ ruby tsl2561.rb
# Last update: 2017/01/10
# author: Sho KANEMARU
#----------------------------------------------------------------------
$LOAD_PATH.push('.')
require "LightSensorLib"
require 'json'
require 'net/http'
require 'uri'
require 'base64'
require 'yaml'
#require 'addressable/uri'

#------------ 設定ファイル読み込み ------------
confFileName = "./config.yml"
config = YAML.load_file(confFileName)

# デバイスID (Cumulocityが払い出したID)
DEVICEID = config["deviceId"]
# CumulocityへのログインID
USERID = config["userId"]
# Cumulocityへのログインパスワード
PASSWD = config["password"]
# I2Cへのファイルパス
I2CPATH = config["i2cpath"]
# CumulocityのURL
URL = config["url"] + "/measurement/measurements/"

# 現在時刻を取得
day = Time.now
time = day.strftime("%Y-%m-%dT%H:%M:%S.000+09:00")
puts time

# TSL2561照度センサから照度情報[lux]を取得
lightSensor = LightSensor.new(I2CPATH)
lightSensor.turnOn
sleep(0.420)
luminosity = lightSensor.getLuminosity
puts "lux=#{luminosity.calcLux}"
#puts "lux2=#{luminosity}"
lightSensor.turnOff

# Cumulocity API用のJSONペイロードを作成
data = {
  :TSL2561_LiminosityMeasurement => {
    :T => {
      :value => luminosity.calcLux,
      :unit => "lux"
    }
  },
  :time => time,
  :source => {
    :id => DEVICEID
  },
  :type => "TSL2561_Measurement"
}

# URLをパース
uri = URI.parse(URL)
#uri = Addressable::URI.parse(URL)
https = Net::HTTP.new(uri.host, uri.port)
https.set_debug_output $stderr
https.use_ssl = true # HTTPSを使用する
#https.use_ssl = false # HTTPSは使用しない

# httpリクエストヘッダの追加
initheader = {
  'Content-Type' =>'application/vnd.com.nsn.cumulocity.measurement+json; charset=UTF-8; ver=0.9',
  'Accept'=>'application/vnd.com.nsn.cumulocity.measurement+json; charset=UTF-8; ver=0.9',
  'Authorization'=>'Basic ' + Base64.encode64("#{USERID}:#{PASSWD}")
}

# httpリクエストの生成、送信
request = Net::HTTP::Post.new(uri.request_uri, initheader)
payload = JSON.pretty_generate(data)
request.body = payload
response = https.request(request)

# 返却の中身を見てみる
puts "------------------------"
puts "code -> #{response.code}"
puts "msg -> #{response.message}"
puts "body -> #{response.body}"

