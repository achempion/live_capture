(()=>{var e=document.querySelector("meta[name='csrf-token']").getAttribute("content"),t=new LiveView.LiveSocket("/live",Phoenix.Socket,{params:{_csrf_token:e}});t.connect();})();
