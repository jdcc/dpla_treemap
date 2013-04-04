var w = 1280 - 80,
    h = 800 - 180,
    x = d3.scale.linear().range([0, w]),
    y = d3.scale.linear().range([0, h]),
    color = d3.scale.category10(),
    root,
    node,
    fudgeFactor = 300;

var treemap = d3.layout.treemap()
    .round(false)
    .size([w, h])
    .sticky(true)
    .value(function(d) { return d.size; });

var svg = d3.select("#body").append("div")
    .attr("class", "chart")
    .style("width", w + "px")
    .style("height", h + "px")
  .append("svg:svg")
    .attr("width", w)
    .attr("height", h)
  .append("svg:g")
    .attr("transform", "translate(.5,.5)");

d3.json("data.json", function(data) {
  node = root = data;

  var nodes = treemap.nodes(root)
     //.filter(function(d) { return !d.children; });

  var cell = svg.selectAll("g")
      .data(nodes)
    .enter().append("svg:g")
      .attr("class", function(d) { return d.children ? "branch" : "cell"; })
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; })
      .on("click", function(d) { return zoom(node == d.parent ? root : d.parent); });

  cell.filter(function(d) { return !d.children; }).append("svg:rect")
      .attr("width", function(d) { return d.dx - 1; })
      .attr("height", function(d) { return d.dy - 1; })
      //.on('mouseover', function() { d3.select(this.parentNode).select('text').style("opacity", 1); })
      //.on('mouseout', function() { d3.select(this.parentNode).select('text').style("opacity", 0); })
      .style("fill", function(d) { return color(d.parent.name); });


  cell.append('foreignObject')
      .attr('width', function(d) { return d.dx; })
      .attr('height', function(d) { return d.dy; })
      .attr('class', 'foreign')
      .append("xhtml:div") 
            .text(function(d) { return d.name + ' (' + d.size + ')'; })
          .style('width', function(d) { return d.dx - 1 + 'px'; })
          .style('height', function(d) { return d.dy  - 1 + 'px'; })
            .attr("class",function(d) { return d.children ? "branch textdiv" : "textdiv"});

  d3.select(window).on("click", function() { zoom(root); });

  d3.select("select").on("change", function() {
    treemap.value(this.value == "size" ? size : count).nodes(root);
    zoom(node);
  });
});

function size(d) {
  return d.size;
}

function count(d) {
  return 1;
}

function zoom(d) {
  var kx = w / d.dx, ky = h / d.dy;
  x.domain([d.x, d.x + d.dx]);
  y.domain([d.y, d.y + d.dy]);

  var t = svg.selectAll("g.cell").transition()
      .duration(d3.event.altKey ? 7500 : 750)
      .attr("transform", function(d) { return "translate(" + x(d.x) + "," + y(d.y) + ")"; });

  t.select("rect")
      .attr("width", function(d) { return kx * d.dx - 1; })
      .attr("height", function(d) { return ky * d.dy - 1; })

  t.select('.foreign')
      .attr("width", function(d) { return kx * d.dx - 1; })
      .attr("height", function(d) { return ky * d.dy - 1; })
      .select('div.textdiv')
          .style("width", function(d) { return kx * d.dx - 1 + 'px'; })
          .style("height", function(d) { return ky * d.dy - 1 + 'px'; })

  node = d;
  d3.event.stopPropagation();
}
