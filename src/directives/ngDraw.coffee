# https://stackoverflow.com/questions/16587961/is-there-already-a-canvas-drawing-directive-for-angularjs-out-there
# make a directive to enable Last Chance Cadet-style drawing between questions and answers

Matching = angular.module 'matching'

Matching.directive 'ngDraw', ->
	restrict: 'A'
	link: (scope, element) ->
		ctx = element[0].getContext '2d'
		ctx.save()
		lastX = null
		lastY = null

		element.bind 'mousedown', (event) ->
			console.log 'sup'
			pos = getPosition event
			lastX = pos[0]
			lastY = pos[1]
			ctx.beginPath()
		element.bind 'mousemove', (event) ->
			draw getPosition event
		element.bind 'mouseup', ctx.restore()

		getPosition = (event) ->
			if event.offsetX
				return [event.offsetX, event.offsetY]
			else
				return [
					event.layerX - event.currentTarget.offsetLeft,
					event.layerY - event.currentTarget.offsetTop
				]

		draw = (position) ->
			ctx.moveTo lastX, lastY
			ctx.lineTo position[0], position[1]
			ctx.strokeStyle = '#000'
			ctx.stroke()
