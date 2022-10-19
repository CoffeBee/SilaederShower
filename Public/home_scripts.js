function openNav() {
	document.getElementById("slidebar").style.width = "332px";
	document.getElementById("main").style.marginLeft = "calc(351px + 69px)";
	document.getElementById("contentInNav").style.visibility = "visible";
	document.getElementById("contentInNav").style.padding = "30px 40px";
	document.getElementById("logoInNav").style.visibility = "hidden";
}
function closeNav() {
	document.getElementById("slidebar").style.width = "165px";
	document.getElementById("main").style.marginLeft = "calc(184px + 69px)";
	document.getElementById("contentInNav").style.visibility = "hidden";
	document.getElementById("logoInNav").style.visibility = "visible";
}
