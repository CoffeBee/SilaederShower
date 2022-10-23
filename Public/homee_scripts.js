function openNav() {
	document.getElementById("slidebar").style.width = "332px";
	//document.getElementById("app").style.marginLeft = "calc(351px + 69px)";
	document.getElementById("contentInNav").style.visibility = "visible";
	document.getElementById("contentInNav").style.padding = "30px 40px";
	document.getElementById("logoInNav").style.visibility = "hidden";
		document.getElementById("plan").style.width = "calc(100vw - 351px - 69px - 30px)";

}
function closeNav() {
	document.getElementById("slidebar").style.width = "165px";
	//document.getElementById("app").style.marginLeft = "calc(184px + 69px)";
	document.getElementById("plan").style.width = "calc(100vw - 184px - 69px - 30px)";

	document.getElementById("contentInNav").style.visibility = "hidden";
	document.getElementById("logoInNav").style.visibility = "visible";

}
