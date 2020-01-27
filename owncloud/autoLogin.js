function autoLogin(){
    document.createElement('form').submit.call(document.getElementById("myLoginForm"));
}

$(document).ready(function() {
    if($("#password").val()) {
        autoLogin();
    }
});
