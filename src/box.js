'use strict'

const BoxSDK = require('box-node-sdk')
const fs = require('fs')
const jsonConfig = require(process.env.BOX_CONFIG)

const sdk = BoxSDK.getPreconfiguredInstance(jsonConfig)
const serviceAccountClient = sdk.getAppAuthClient('enterprise')

const fileName = process.env.UPLOAD_FILE
const fileId = process.env.UPLOAD_ID

serviceAccountClient.files.uploadNewFileVersion(fileId, fs.createReadStream(fileName)).then(
  function (user) { console.log('File uploaded', fileName, fileId) }
).catch(
  function (err) { console.log('Got an error', err) }
)
