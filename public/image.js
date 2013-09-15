/* Function for Image
 *  - Swap image file
 */

function findObjByName(name)
{
	var i;
	if(document[name]){
		return document[name];
	}
	if(document.all && document.all[name]){
		return document.all[name];
	}
	for(i=0; i < document.forms.length; i++){
		if(document.forms[i][name]){
			return document.forms[i][name];
		}
	}
	return null;
}


/* Swap image */
var imgSrc = new Array();
var imgObj = new Array();

function swapImg()
{
	var i;
	var j = 0;
	var a = swapImg.arguments;

	restoreImg();

	for(i=0; i<a.length; i+=2){
		var obj = findObjByName(a[i]);
		if(obj != null){
			imgObj[j] = obj;
			imgSrc[j] = obj.src;
			j++;
			obj.src = a[i+1];
		}
	}
}

function restoreImg()
{
	var i;
	for(i=0; i<imgObj.length; i++){
		imgObj[i].src = imgSrc[i];
	}
	imgSrc = new Array();
	imgObj = new Array();
}


/* Chenge Style */
var styleClass = new Array();
var styleObj   = new Array();

function swapStyle()
{
	var i;
	var j = 0;
	var a = swapStyle.arguments;

	restoreStyle();

	for(i=0; i<a.length; i+=2){
		var obj = document.getElementById(a[i]);
		if(obj != null){
			styleObj[j]   = obj;
			styleClass[j] = obj.className;
			j++;
			obj.className = a[i+1];
		}
	}
}

function swapStyleByObj()
{
	var i;
	var j = 0;
	var a = swapStyleByObj.arguments;

	restoreStyle();

	for(i=0; i<a.length; i+=2){
		var obj = a[i];
		if(obj != null){
			styleObj[j]   = obj;
			styleClass[j] = obj.className;
			j++;
			obj.className = a[i+1];
		}
	}
}

function restoreStyle()
{
	var i;
	for(i=0; i<styleObj.length; i++){
		styleObj[i].className = styleClass[i];
	}
	styleClass = new Array();
	styleObj   = new Array();
}
