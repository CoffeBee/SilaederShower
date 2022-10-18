function show_hide_password(target){
	var input = document.getElementById('password-input');
	if (input.getAttribute('type') == 'password') {
		target.classList.remove('view');
		input.setAttribute('type', 'text');
	} else {
		target.classList.add('view');
		input.setAttribute('type', 'password');
	}
	return false;
}

function become_visible() {
	var input = document.getElementById('password-input');
	var eye = document.getElementById('eye');
	if (input.value == ""){
		eye.setAttribute("style", "visibility: hidden;");
	} else {
		eye.setAttribute("style", "visibility: visible;");
	}
}