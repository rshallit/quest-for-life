function makeChart(parameter, dimension, selectedValue) {
    var options = {
	chart: {
	    renderTo: dimension + '-chart',
	    defaultSeriesType: 'column'
	},
	xAxis: {
	    categories: []
	},
	yAxis: {
	    title: {
		text: 'Number of Responses'
	    }
	},
	credits: {
	    enabled: false
	},
	legend: {
	    enabled: false
	},
	series: [{
		name: 'Count',
		data: []
	    }],
	tooltip: {
	    formatter: function() {
		return '' + this.y +' users responded with '+ this.x.toLowerCase();
	    }
	}
    };
    $.getJSON(['/surveys', 'report', parameter, dimension].join('/'), {selected_value: selectedValue}, function(data) {
	    options.title = {text: data.caption};
	    $.each(data.data, function(index, row) {
		    options.xAxis.categories.push(row[0]);
		    options.series[0].data.push(row[1]);
		});
	    var chart = new Highcharts.Chart(options);
	});
}

$(function() {
	makeChart(currentParameter, 'all', '');
	$.each(['age', 'gender'], function(index, dimension) {
		var select = $('#' + dimension + '_select');
		select.change(function() {
			makeChart(currentParameter, dimension, $(this).val());
		    });
		select.change();
	    });
    });

