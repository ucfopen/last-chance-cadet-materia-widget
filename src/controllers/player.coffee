Matching = angular.module 'matching'

Matching.controller 'matchingPlayerCtrl', ['$scope', '$timeout', '$sce', ($scope, $timeout, $sce) ->
	materiaCallbacks = {}
	$scope.title = ''

	$scope.pages = []
	$scope.selectedQA = []
	$scope.matches = []
	$scope.prelines = []

	$scope.lines = []
	$scope.questionCircles = []
	$scope.answerCircles = []

	$scope.totalPages = 1
	$scope.currentPage = 0
	$scope.totalItems = 0
	$scope.setCreated = false
	$scope.helpVisible = false
	$scope.completePerPage = []

	$scope.unfinishedPagesBefore = false
	$scope.unfinishedPagesAfter = false
	helpModal = document.getElementById("instructions");
	helpModal.inert = true;



	_assistiveAlert = (msg) ->
		alertEl = document.getElementById('assistive-alert')
		if alertEl then alertEl.innerHTML = msg
	

	$scope.qset = {}

	$scope.circumference = Math.PI * 80

	_boardElement = document.getElementById('gameboard')

	# these are used for animation
	$scope.pageAnimate = false
	$scope.pageNext = false
	ANIMATION_DURATION = 600

	colorNumber = 0

	ITEMS_PER_PAGE = 6
	NUM_OF_COLORS = 7
	CIRCLE_START_X = 20
	CIRCLE_END_X = 190
	CIRCLE_RADIUS = 10
	CIRCLE_SPACING = 72
	CIRCLE_OFFSET = 40
	PROGRESS_BAR_LENGTH = 160


	materiaCallbacks.start = (instance, qset) ->
		$scope.qset = qset
		$scope.title = instance.name
		$scope.totalItems = qset.items[0].items.length
		$scope.totalPages = Math.ceil $scope.totalItems/ITEMS_PER_PAGE

		document.title = instance.name + ' Materia widget'

		# set up the pages
		for [1..$scope.totalPages]
			$scope.pages.push {questions:[], answers:[]}
			$scope.selectedQA.push {question:-1, answer:-1}
			$scope.questionCircles.push []
			$scope.answerCircles.push []
			$scope.completePerPage.push 0

		_itemIndex = 0
		_pageIndex = 0
		_indexShift = 0
		# Splits the the last items over the last two pages
		_leftover = $scope.totalItems % ITEMS_PER_PAGE
		_splitPoint = ~~(4 + (_leftover - 1)/2)
		if _leftover == 0
			_splitPoint = -1

		for item in qset.items[0].items
			if _itemIndex == ITEMS_PER_PAGE or (_pageIndex == $scope.totalPages - 2 && _itemIndex == _splitPoint)
				_shuffle $scope.pages[_pageIndex].questions
				_shuffle $scope.pages[_pageIndex].answers
				_itemIndex = 0
				_indexShift = 0
				_pageIndex++

			wrapQuestionUrl = ->
				if item.assets[0] != 0 and item.assets[0] != undefined # for qsets published after this commit, this value will be 0, for older qsets it's undefined
					return $sce.trustAsResourceUrl Materia.Engine.getImageAssetUrl(item.assets[0])

			$scope.pages[_pageIndex].questions.push {
				text: if item.questions[0].text then item.questions[0].text else '[No Text Provided!]'
				id: item.id
				pageId: _pageIndex
				type: 'question'
				asset: wrapQuestionUrl()
			}

			$scope.questionCircles[_pageIndex].push {
				r:CIRCLE_RADIUS
				cx: CIRCLE_START_X
				cy:CIRCLE_SPACING * _itemIndex + CIRCLE_OFFSET
				id:_itemIndex
				isHover: false
				lightHover: false
				type: 'question-circle'
				color: 'c0'
			}

			###
			We're not using fakeout options yet, restore this when they're ready
			# Adjust if this is a 'fakeout' answer option
			if item.assets[1] == 0 and not item.answers[0].text.length
				_itemIndex++
				_indexShift++
				$scope.totalItems--
				continue
			###

			wrapAnswerUrl = ->
				if item.assets[1] != 0 and item.assets[1] != undefined # for qsets published after this commit, this value will be 0, for older qsets it's undefined
					return $sce.trustAsResourceUrl Materia.Engine.getImageAssetUrl(item.assets[1])

			$scope.pages[_pageIndex].answers.push {
				text: if item.answers[0].text then item.answers[0].text else '[No Text Provided!]'
				id: item.id
				pageId: _pageIndex
				type: 'answer'
				asset: wrapAnswerUrl()
			}

			$scope.answerCircles[_pageIndex].push {
				r:CIRCLE_RADIUS
				cx: CIRCLE_END_X
				cy:CIRCLE_SPACING * (_itemIndex - _indexShift) + CIRCLE_OFFSET
				id:_itemIndex
				isHover: false
				lightHover: false
				type: 'answer-circle'
				color: 'c0'
				hackRotation: "rotate("+Math.floor(Math.random()*360)+" 0 0)"
			}

			_itemIndex++

		# final shuffling for last page
		_shuffle $scope.pages[_pageIndex].questions
		_shuffle $scope.pages[_pageIndex].answers
		$scope.setCreated = true

		Materia.Engine.setHeight()
		$scope.$apply()

	$scope.changePage = (direction) ->
		return false if $scope.pageAnimate
		return false if direction == 'previous' and $scope.currentPage <= 0
		return false if direction == 'next' and $scope.currentPage >= $scope.totalPages - 1

		_clearSelections()
		$scope.pageAnimate = true

		$scope.pageNext = (direction == 'next')
		$timeout ->
			$scope.currentPage-- if direction == 'previous'
			$scope.currentPage++ if direction == 'next'
			_checkUnfinishedPages()
		, ANIMATION_DURATION/3

		if $scope.pageAnimate
			$timeout ->
				$scope.pageAnimate = false
			, ANIMATION_DURATION*1.1

		if _boardElement then _boardElement.focus()
		if direction == 'next' then _assistiveAlert 'Page incremented. You are on the next page.'
		else if direction == 'previous' then _assistiveAlert 'Page decremented. You are on the previous page.'


	_updateCompletionStatus = () ->
		$scope.completePerPage  = []
		for match in $scope.matches
			if !$scope.completePerPage[match.matchPageId] then $scope.completePerPage[match.matchPageId] = 1
			else $scope.completePerPage[match.matchPageId]++

	
       



	$scope.checkForQuestionAudio = (index) ->
		$scope.pages[$scope.currentPage].questions[index].asset != undefined

		

	$scope.checkForAnswerAudio = (index) ->
		$scope.pages[$scope.currentPage].answers[index].asset != undefined


	_pushMatch = () ->
		$scope.matches.push {
			questionId: $scope.selectedQuestion.id
			questionIndex: $scope.selectedQA[$scope.currentPage].question
			answerId: $scope.selectedAnswer.id
			answerIndex: $scope.selectedQA[$scope.currentPage].answer
			matchPageId: $scope.currentPage
			color: _getColor()
	
		}
		_updateCompletionStatus()

		if $scope.matches.length == $scope.totalItems then _assistiveAlert 'All matches complete. The finish button is now available.'

	_applyCircleColor = () ->
		# find appropriate circle
		$scope.questionCircles[$scope.currentPage][$scope.selectedQA[$scope.currentPage].question].color = _getColor()
		$scope.answerCircles[$scope.currentPage][$scope.selectedQA[$scope.currentPage].answer].color = _getColor()

	_getColor = () ->
		'c' + colorNumber

	_checkForMatches = () ->
		if $scope.selectedQA[$scope.currentPage].question != -1 and $scope.selectedQA[$scope.currentPage].answer != -1
			# check if the id already exists in matches
			clickQuestionId = $scope.selectedQuestion.id
			clickAnswerId = $scope.selectedAnswer.id

			# increment color cycle
			colorNumber = (colorNumber+1)%NUM_OF_COLORS
			if colorNumber == 0
				colorNumber = 1

			# if the id of the question exists in a set of matches, delete that set of matches
			# get the index of the match where the question/answer exists
			indexOfQuestion = $scope.matches.map((element) -> element.questionId).indexOf clickQuestionId
			indexOfAnswer = $scope.matches.map((element) -> element.answerId).indexOf clickAnswerId

			if indexOfQuestion >= 0
				match1_QIndex = $scope.matches[indexOfQuestion].questionIndex
				match1_AIndex = $scope.matches[indexOfQuestion].answerIndex

			if indexOfAnswer >= 0
				match2_QIndex = $scope.matches[indexOfAnswer].questionIndex
				match2_AIndex = $scope.matches[indexOfAnswer].answerIndex

			# if both question and answer are in matches then take out where they exist in matches
			if indexOfQuestion != -1 and indexOfAnswer != -1
				# need to account here for the indexOfQuestion and indexOfAnswer being the same
				$scope.questionCircles[$scope.currentPage][match1_QIndex].color = 'c0'
				$scope.questionCircles[$scope.currentPage][match2_QIndex].color = 'c0'

				$scope.answerCircles[$scope.currentPage][match1_AIndex].color = 'c0'
				$scope.answerCircles[$scope.currentPage][match2_AIndex].color = 'c0'

				$scope.matches.splice indexOfQuestion, 1
				# only proceed to do the following if the index of question and answer
				# are not the same- otherwise an extra pair will be deleted
				if indexOfQuestion != indexOfAnswer
					if indexOfAnswer > indexOfQuestion
						# we have to subtract 1 to account for the previous slice
						$scope.matches.splice indexOfAnswer-1, 1
					else
						# in this case we don't need to subtract to account for splice
						$scope.matches.splice indexOfAnswer, 1
			# only the question exists in a match
			else if indexOfQuestion != -1  and indexOfAnswer == -1
				$scope.questionCircles[$scope.currentPage][match1_QIndex].color = 'c0'
				$scope.answerCircles[$scope.currentPage][match1_AIndex].color = 'c0'
				$scope.matches.splice indexOfQuestion, 1
			# only the answer exists in a match
			else if indexOfQuestion == -1 and indexOfAnswer != -1
				$scope.questionCircles[$scope.currentPage][match2_QIndex].color = 'c0'
				$scope.answerCircles[$scope.currentPage][match2_AIndex].color = 'c0'
				$scope.matches.splice indexOfAnswer, 1

			_assistiveAlert $scope.pages[$scope.currentPage].questions[$scope.selectedQA[$scope.currentPage].question].text + ' matched with ' + 
					$scope.pages[$scope.currentPage].answers[$scope.selectedQA[$scope.currentPage].answer].text


			_pushMatch()

			_applyCircleColor()

			_clearSelections()

			_updateLines()

			_checkUnfinishedPages()

			$scope.unapplyHoverSelections()

		else if $scope.selectedQA[$scope.currentPage].question != -1 then _assistiveAlert $scope.selectedQuestion.text + ' selected.'
		else if $scope.selectedQA[$scope.currentPage].answer != -1 then _assistiveAlert $scope.selectedAnswer.text + ' selected.'

	_clearSelections = () ->
		$scope.selectedQA[$scope.currentPage].question = -1
		$scope.selectedQA[$scope.currentPage].answer = -1


	_updateLines = () ->
		$scope.lines = []
		for [1..$scope.totalPages]
			$scope.lines.push []
		for match in $scope.matches
			targetStartY = $scope.questionCircles[match.matchPageId][match.questionIndex].cy
			targetEndY = $scope.answerCircles[match.matchPageId][match.answerIndex].cy
			$scope.lines[match.matchPageId].push {
				startX:CIRCLE_START_X
				startY:targetStartY
				endX:CIRCLE_END_X
				endY:targetEndY
				color:match.color
			}

	$scope.getPercentDone = () ->
		return 0 if $scope.totalItems is 0 or $scope.matches.length is 0
		$scope.matches.length / $scope.totalItems

	$scope.getProgressAmount = () ->
		if $scope.totalItems == 0
			return 0
		return $scope.matches.length / $scope.totalItems * PROGRESS_BAR_LENGTH

	$scope.applyCircleClass = (selectionItem) ->
		# selectionItem.id is the index of circle
		if selectionItem.type == 'question-circle'
			if selectionItem.id == $scope.selectedQA[$scope.currentPage].question
				return true
		if selectionItem.type == 'answer-circle'
			if selectionItem.id == $scope.selectedQA[$scope.currentPage].answer
				return true
		false

	$scope.applyQuestionClass = (index) ->
		if index == $scope.selectedQA[$scope.currentPage].question
			return true
		false

	$scope.applyAnswerClass = (index) ->
		if index == $scope.selectedQA[$scope.currentPage].answer
			return true
		false

	$scope.unapplyHoverSelections = () ->
		$scope.prelines = []
		$scope.questionCircles[$scope.currentPage].forEach (element) ->
			element.isHover = false
			element.lightHover = false
		$scope.answerCircles[$scope.currentPage].forEach (element) ->
			element.isHover = false
			element.lightHover = false

	$scope.getMatchColor = (item) ->
		if $scope.isInMatch(item)
			if item.type == 'question'
				matchedItem = $scope.matches.filter( (match) -> match.questionId == item.id)[0]
			else if item.type == 'answer'
				matchedItem = $scope.matches.filter( (match) -> match.answerId == item.id)[0]
			matchedItem.color
		else
			'c0'

	# truthiness evaluated from function return
	$scope.isInMatch = (item) ->
		if item.type == 'question'
			return $scope.matches.some( (match) -> match.questionId == item.id)

		if item.type == 'answer'
			return $scope.matches.some( (match) -> match.answerId == item.id)

		return false

	$scope.getMatchWith = (item) ->
		if item.type == 'question'
			a = $scope.matches.find( (match) -> match.questionId == item.id)
			if a then return $scope.pages[a.matchPageId].answers[a.answerIndex].text

		else if item.type == 'answer'
			q = $scope.matches.find( (match) -> match.answerId == item.id)
			if q then return $scope.pages[q.matchPageId].questions[q.questionIndex].text

	$scope.drawPrelineToRight = (hoverItem) ->
		elementId = hoverItem.id
		# get the index of the item in the current page by finding it with its id
		endIndex = $scope.pages[$scope.currentPage].answers.map((element) ->
			if(element != undefined)
				element.id
			).indexOf elementId

		# exit if a question has not been selected
		if $scope.selectedQA[$scope.currentPage].question == -1
			$scope.answerCircles[$scope.currentPage][endIndex].lightHover = true
			return

		startIndex = $scope.selectedQA[$scope.currentPage].question

		if $scope.prelines.length > 0
			$scope.prelines = []

		$scope.prelines.push {
			# left column
			linex1 : $scope.questionCircles[$scope.currentPage][startIndex].cx
			# right column
			linex2 : $scope.answerCircles[$scope.currentPage][endIndex].cx

			# left column
			liney1 : $scope.questionCircles[$scope.currentPage][startIndex].cy
			# right column
			liney2 : $scope.answerCircles[$scope.currentPage][endIndex].cy
		}
		$scope.answerCircles[$scope.currentPage][endIndex].isHover = true

	$scope.drawPrelineToLeft = (hoverItem) ->
		elementId = hoverItem.id
		# get the index of the item in the current page by finding it with its id
		endIndex = $scope.pages[$scope.currentPage].questions.map((element) ->
			if(element != undefined)
				element.id
		).indexOf elementId

		# exit if a question has not been selected
		if $scope.selectedQA[$scope.currentPage].answer == -1
			$scope.questionCircles[$scope.currentPage][endIndex].lightHover = true
			return

		startIndex = $scope.selectedQA[$scope.currentPage].answer

		if $scope.prelines.length > 0
			$scope.prelines = []

		$scope.prelines.push {
			# right column
			linex1 : $scope.answerCircles[$scope.currentPage][startIndex].cx
			# left column
			linex2 : $scope.questionCircles[$scope.currentPage][endIndex].cx

			# right column
			liney1 : $scope.answerCircles[$scope.currentPage][startIndex].cy
			# left column
			liney2 : $scope.questionCircles[$scope.currentPage][endIndex].cy
		}
		$scope.questionCircles[$scope.currentPage][endIndex].isHover = true

	$scope.keydownHandler = (event) ->
		# keyboard input for the widget
		switch event.code
			# 1 - 6 will select the question in column 1
			when "Digit1" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[0])
			when "Digit2" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[1])
			when "Digit3" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[2])
			when "Digit4" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[3])
			when "Digit5" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[4])
			when "Digit6" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[5])
			# QWERTY will select the answer in column 2
			when "KeyQ" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[0])
			when "KeyW" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[1])
			when "KeyE" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[2])
			when "KeyR" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[3])
			when "KeyT" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[4])
			when "KeyY" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[5])
			# left and right arrow keys will change the page
			when "ArrowLeft"  then document.getElementsByClassName('column1')[0].getElementsByClassName('word')[0].focus()
			when "ArrowRight" then document.getElementsByClassName('column2')[0].getElementsByClassName('word')[0].focus()
	
			# enter and space will function the same as clicking on the focused element
			when "Enter", "Space"
				switch window.document.activeElement.id
					when "question-choice 0" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[0])
					when "question-choice 1" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[1])
					when "question-choice 2" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[2])
					when "question-choice 3" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[3])
					when "question-choice 4" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[4])
					when "question-choice 5" then $scope.selectQuestion($scope.pages[$scope.currentPage].questions[5])

					when "answer-choice 0" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[0])
					when "answer-choice 1" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[1])
					when "answer-choice 2" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[2])
					when "answer-choice 3" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[3])
					when "answer-choice 4" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[4])
					when "answer-choice 5" then $scope.selectAnswer($scope.pages[$scope.currentPage].answers[5])

					when "previous-page" then $scope.changePage('previous')
					when "next-page" then $scope.changePage('next')

					when "finish-button" then $scope.submit()


	$scope.getItemLetter = (index) ->
		# determines the letter that will be displayed next to each answer choice in the second column
		switch index
			when 0 then "Q"
			when 1 then "W"
			when 2 then "E"
			when 3 then "R"
			when 4 then "T"
			when 5 then "Y"

	$scope.selectQuestion = (selectionItem) ->
		elementId = selectionItem.id
		# get the index of the item in the current page by finding it with its id
		indexId = $scope.pages[$scope.currentPage].questions.map((element) -> element.id).indexOf elementId
		# selectedQuestion allows us to find the item we want in our initialized question array at the specified index
		# selectedQuestion represents the question [left] column selection
		$scope.selectedQuestion = $scope.pages[$scope.currentPage].questions[indexId]
		# selectedQA stores the index of the current selected answer and question for a particular page
		$scope.selectedQA[$scope.currentPage].question = indexId
		_checkForMatches()

	$scope.selectAnswer = (selectionItem) ->
		elementId = selectionItem.id
		# get the index of the item in the current page by finding it with its id
		indexId = $scope.pages[$scope.currentPage].answers.map((element) -> element.id).indexOf elementId
		# selectedAnswer allows us to find the item we want in our initialized question array at the specified index
		# selectedAnswer represents the answer [right] column selection
		$scope.selectedAnswer = $scope.pages[$scope.currentPage].answers[indexId]
		# selectedQA stores the index of the current selected answer and question for a particular page
		$scope.selectedQA[$scope.currentPage].answer = indexId
		_checkForMatches()


	$scope.submit = () ->
		return if $scope.getPercentDone() < 1
		qsetItems = $scope.qset.items[0].items

		for i in [0..qsetItems.length-1]
			# get id of the current qset item use that as the 1st argument
			# find the id of that qset item in the matches object array
			matchedItem = $scope.matches.filter( (match) -> match.questionId == qsetItems[i].id)
			if matchedItem?.length
				matchedItemAnswerId = matchedItem[0].answerId
				# get the answer of that match at that question id and use that as the 2nd argument
				mappedQsetItemText = qsetItems.filter( (item) -> item.id == matchedItemAnswerId)[0].answers[0].text
				mappedQsetAudioString = qsetItems.filter( (item) -> item.id == matchedItemAnswerId)[0].assets[2]
			else
				mappedQsetItemText = null
			Materia.Score.submitQuestionForScoring(qsetItems[i].id, mappedQsetItemText, mappedQsetAudioString)
		Materia.Engine.end true

	_shuffle = (qsetItems) ->
		# don't shuffle if less than 2 elements
		return qsetItems unless qsetItems.length >= 2
		for index in [1..qsetItems.length-1]
			randomIndex = Math.floor Math.random() * (index + 1)
			[qsetItems[index], qsetItems[randomIndex]] = [qsetItems[randomIndex], qsetItems[index]]

	$scope.setIsFirstPage = () ->
		isFirstPage = false
		if $scope.currentPage == 0
			isFirstPage = true
		return isFirstPage
	
	$scope.setIsLastPage = () ->
		isLastPage = false
		if $scope.currentPage == $scope.pages.length - 1
			isLastPage = true
		return isLastPage
		
	
	
	
	

	_checkUnfinishedPages = () ->
		$scope.unfinishedPagesBefore = false
		$scope.unfinishedPagesAfter = false

		pairsPerPage = []
		matchesPerPage = []
		for index in [0..$scope.pages.length-1]
			pairsPerPage[index] = $scope.pages[index].answers.length
			matchesPerPage[index] = 0
		for match in $scope.matches
			matchesPerPage[match.matchPageId]++

		unless $scope.currentPage == 0
			for page in [0..$scope.currentPage]
				if matchesPerPage[page] < pairsPerPage[page]
					if matchesPerPage[$scope.currentPage] == pairsPerPage[$scope.currentPage]
						$scope.unfinishedPagesBefore = true

		unless $scope.currentPage == $scope.pages.length - 1
			for page in [$scope.currentPage..pairsPerPage.length]
				if matchesPerPage[page] < pairsPerPage[page]
					if matchesPerPage[$scope.currentPage] == pairsPerPage[$scope.currentPage]
						$scope.unfinishedPagesAfter = true

	$scope.unfocused = () ->
		$scope.helpVisible = !$scope.helpVisible
		helpButton = document.getElementById("help-button");
		gameBoard = document.getElementById("gameboard");
		panelButtons = document.getElementById("page-selector");
		finishButton = document.getElementById("finish-button");
		

		panelButtons.inert = true;
		helpButton.inert = true;
		gameBoard.inert = true;
		finishButton.inert = true;

		helpModal.inert = false;

	$scope.focused = () ->
		
		$scope.helpVisible = false
		helpButton = document.getElementById("help-button");
		gameBoard = document.getElementById("gameboard");
		panelButtons = document.getElementById("page-selector");
		finishButton = document.getElementById("finish-button");
		

		panelButtons.inert = false;
		helpButton.inert = false;
		gameBoard.inert = false;
		finishButton.inert = false;

		
		helpModal.inert = true;
		
						
	Materia.Engine.start materiaCallbacks
]