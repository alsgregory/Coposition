window.COPO = window.COPO || {};
window.COPO.charts = {
  drawChart: function() {
    // Define the chart to be drawn.
    var data = new google.visualization.DataTable();
    data.addColumn('string', 'created_at');
    data.addColumn('number', 'Checkins');
    data.addRows(gon.chart_checkins);
    var gap = Math.round(gon.chart_checkins.length/10)
    var options = {
      hAxis: { title: 'Date',  showTextEvery: gap },
      vAxis: { title: 'Checkins' },
    };

    // Instantiate and draw the chart.
    var chart = new google.visualization.ColumnChart(document.getElementById('line-chart'));

    function selectHandler() {
      var selectedItem = chart.getSelection()[0];
      if (selectedItem) {
        var splitColumnDate = gon.chart_checkins[selectedItem.row][0].split("/");
        gon.table_checkins = [];

        if (splitColumnDate.length === 3){
          var columnDate = new Date(splitColumnDate[2], splitColumnDate[1]-1, splitColumnDate[0]);
          gon.checkins.forEach(function(checkin){
            date = new Date(new Date(checkin.created_at).setHours(0,0,0,0));
            if (date.toString() === columnDate.toString()){
              gon.table_checkins.push(checkin);
            }
          })
        } else if (splitColumnDate.length ===2) {
          gon.checkins.forEach(function(checkin){
            var month = new Date(checkin.created_at).getMonth();
            var year = new Date(checkin.created_at).getFullYear().toString();
            if (month == splitColumnDate[0]-1 && year.substr(year.length-2) == splitColumnDate[1]){
              gon.table_checkins.push(checkin);
            }
          })
        }

        COPO.charts.drawTable();
      }
    }

    // Listen for the 'select' event, and call my function selectHandler() when
    // the user selects something on the chart.
    google.visualization.events.addListener(chart, 'select', selectHandler);
    chart.draw(data, options);
  },

  drawTable: function() {
    // Define the chart to be drawn.
    var tableData = [];
    gon.table_checkins.forEach(function(checkin){
      var humanizedDate = new Date(checkin.created_at).toLocaleDateString('en-GB')
      var fogging = COPO.utility.ujsLink('put', '<i class="material-icons">cloud</i>' , window.location.pathname + '/checkins/' + checkin.id )[0];
      tableData.push([humanizedDate, checkin.fogged_area, fogging.outerHTML]);
    })
    var data = new google.visualization.DataTable();
    data.addColumn('string', 'Created');
    data.addColumn('string', 'Area');
    data.addColumn('string', 'Fogging');
    data.setColumnProperty(2, {allowHtml: true})
    data.addRows(tableData);

    // Instantiate and draw the chart.
    var table = new google.visualization.Table(document.getElementById('table-chart'));
    var options = { width: '100%', height: '100%', allowHtml: true }
    table.draw(data, options);
  }
}


