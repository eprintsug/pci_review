var initLDNListener = function(){

    var ldn_btns = document.getElementsByClassName('pci_content_toggle');

    for (var i = 0; i < ldn_btns.length; i++) {
        ldn_btns[i].addEventListener('click', ldn_toggle, false);
    }
};

var ldn_toggle = function(){

    var content = this.parentNode.parentNode.querySelector('.pci_content');

    if(content.classList.contains("pci_content_hide") )
    {
        content.classList.remove("pci_content_hide");
        this.textContent = "Hide content";
    } 
    else
    {
        content.classList.add("pci_content_hide");
        this.textContent = "Show content";
    }
};
