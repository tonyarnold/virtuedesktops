// setup
function setup() {
   renderBoxes();
}

// AppleScripts for Desktop handling
// Switch Desktop
function switchTo(dn) {
    var script = AppleScript.scriptFromString("tell application \"VirtueDesktops\" to show desktop " + dn);
    script();
}

// Get total number of Desktops
function printTotal() {
    document.write("You have <strong>" + totalDesktops() + "</strong> desktops.");
}

function totalDesktops()
{
  var totalScript = AppleScript.scriptFromString("tell application \"VirtueDesktops\" to return number of desktops");
  return totalScript();  
}

function getRows()
{
  return Math.round(totalDesktops() / getColumns());
}

function getColumns()
{
  return 2;
}

function windowHeight()
{
  return getRows() * (58 + 4);
}

function windowWidth()
{
  return getColumns() * (96 + 4);
}

function renderBoxes()
{
  window.resizeTo(windowWidth(), windowHeight());
  alert("resizing window to " + windowWidth() + "px by "+ windowHeight() + "px (rows: " +getRows()+" cols: "+getColumns()+")");
  var renderDiv = document.getElementById("front");
     
  while (renderDiv.hasChildNodes())
  {
    renderDiv.removeChild(renderDiv.firstChild);
  }
  
  for (var i = 0; i < totalDesktops(); i++)
  {
    var newImage = document.createElement("img");
    newImage.src = "Desktop Representation.png";
    newImage.align = "left";
    newImage.setAttribute("onclick", "switchTo("+ (i+1) +")");
    renderDiv.appendChild(newImage);
  }
  setTimeout('renderBoxes()', 5000);
}
