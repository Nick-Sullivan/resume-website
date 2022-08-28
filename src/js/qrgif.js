const BASE_URL = "https://evew394e8d.execute-api.ap-southeast-2.amazonaws.com/v1"
const MAX_FILE_SIZE = 5 * 1024 * 1024

// Input events

function fileUploaded() {
	const file = document.getElementById('inputFile').files[0]
	if(file.size > MAX_FILE_SIZE ){
		alert("File is too big")
		return
 };

	const inputImage = document.getElementById('inputImage')
	inputImage.src = URL.createObjectURL(file)
	
	enableQrText()
	enableBinaryThreshold()
	updateSampleImage()
	updateGenerateButton()
}

function qrTextChanged() {
	updateGenerateButton()
}

function binaryThresholdChanged() {
	updateSampleImage()
}

function generateButtonClicked() {
	const qrText = document.getElementById('qrText').value
	const binaryThreshold = document.getElementById('binaryThreshold').value
	const outputImage = document.getElementById('outputImage')
	outputImage.src = "https://upload.wikimedia.org/wikipedia/commons/b/b1/Loading_icon.gif"

	const file = document.getElementById('inputFile').files[0];
	processImage(file, qrText, binaryThreshold)
		.then(response => response.json())
		.then(json => outputImage.src = json.url)
}

// State changes

function enableQrText() {
	const generateButton = document.getElementById('qrText')
	generateButton.disabled = false
}

function enableBinaryThreshold() {
	const generateButton = document.getElementById('binaryThreshold')
	generateButton.disabled = false
}

function updateGenerateButton() {
	const generateButton = document.getElementById('generateButton')
	generateButton.disabled = !isGenerateReady()
}

function isGenerateReady() {

	const qrText = document.getElementById('qrText').value
	if (qrText.length == 0) {
		return false
	}

	const files = document.getElementById('inputFile').files
	if (files.length == 0) {
		return false
	}

	return true
}

function updateSampleImage(){
	const inputImage = document.getElementById('inputImage')
	const binaryThreshold = document.getElementById('binaryThreshold').value
	const sampleOutput = document.getElementById("sampleImage");

	var image = new MarvinImage();
	image.load(inputImage.src, function(){
		let newImage = processSampleImage(image, binaryThreshold)
		newImage.draw(sampleOutput);
	});
}

// Internal processing, no DOM interaction

function processSampleImage(image, binaryThreshold){
	
	let minLength = Math.min(image.getWidth(), image.getHeight())
	let x = (image.getWidth() - minLength ) / 2
	let y = (image.getHeight() - minLength ) / 2

	let newImage = image.clone()
	Marvin.crop(newImage.clone(), newImage, x, y, x+minLength, y+minLength)
	Marvin.scale(newImage.clone(), newImage, 80, 80)
	Marvin.scale(newImage.clone(), newImage, 320, 320)
	Marvin.thresholding(newImage, newImage, binaryThreshold)
	return newImage
}

// Server interaction

async function sendHello() {
	console.log("Sending hello")
	let response = await fetch(`${BASE_URL}/basic`, {
		method: 'POST',
		body: JSON.stringify({
			"message": "hello"
		}),
		headers: {
			'Content-Type': 'application/json',
		}
	})
	console.log(`status: ${response.status}`)
	let json = await response.json()
	console.log(json)
	return json
}

async function uploadImage(data){
	console.log("Uploading image")
	let response = await fetch(`${BASE_URL}/upload`, {
		method: 'POST',
		body: data,
		headers: {
			'Content-Type': 'image/gif',
		}
	})
	console.log(`status: ${response.status}`)
	let json = await response.json()
	console.log(json)

	const imageOutput = document.getElementById('output');
	imageOutput.src = json.url

	return response
}

async function processImageBasic(data){
	const imageUrl = "https://i.picsum.photos/id/566/200/300.jpg?hmac=gDpaVMLNupk7AufUDLFHttohsJ9-C17P7L-QKsVgUQU";
	let response = await fetch(imageUrl)
	return response
}

async function processImage(data, qrText, binaryThreshold) {
	console.log("Sending image for processing")
	let response = await fetch(`${BASE_URL}/process`, {
		method: 'POST',
		body: data,
		headers: {
			'Content-Type': 'image/gif',
			'QRText': qrText,
			'QRPixelation': 80,
			'QRBinaryThreshold': binaryThreshold,
		}
	})
	console.log(`status: ${response.status}`)
	return response
}
