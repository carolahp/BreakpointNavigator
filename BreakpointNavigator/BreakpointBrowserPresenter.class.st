"
I browse halts and breakpoints of the system.
I add and fix problems of `StDebuggerBreakpointInspection`, and I should later be merged with it.
"
Class {
	#name : #BreakpointBrowserPresenter,
	#superclass : #StDebuggerBreakpointInspection,
	#instVars : [
		'breakpointedMethods',
		'methodsToNodesMap'
	],
	#category : #BreakpointNavigator
}

{ #category : #extensions }
BreakpointBrowserPresenter class >> breakpointCommandsWith: presenter forRootGroup: aCmCommandsGroup [
	<extensionCommands>
	
	aCmCommandsGroup
		register: (self removeBreakpointCommandFor: presenter);
		register: (self browseBreakpointMethodCommandFor: presenter)
]

{ #category : #specs }
BreakpointBrowserPresenter class >> defaultSpec [

	^ SpPanedLayout newVertical
		  add: (SpPanedLayout newHorizontal
				   positionOfSlider: 60 percent;
				   add: #methodsWithBreakpoints;
				   add: #breakpointedMethods;
				   yourself);
		  add: #breakpointsInSourceCode;
		  yourself
]

{ #category : #'world menu' }
BreakpointBrowserPresenter class >> menuCommandOn: aBuilder [

	<worldMenu>
	(aBuilder item: #'Breakpoint Navigator')
		parent: #Debug;
		action: [ self new openWithSpec ];
		order: -1;
		help: 'A breakpoint navigator that allows you to browse, uninstall and (de)activate breakpoints at will.';
		icon: (self iconNamed: #glamorousBug).
	aBuilder withSeparatorAfter
]

{ #category : #extensions }
BreakpointBrowserPresenter class >> removeBreakpointCommandFor: presenter [
	| cmd |
	cmd := BreakpointBrowserRemoveBreakpointCommand forSpecContext: presenter.
	cmd iconName: #smallDelete.
	cmd innerCommand
		transform: [ :ctx | ctx methodsWithBreakpoints selection selectedItem ].
	^ cmd
]

{ #category : #private }
BreakpointBrowserPresenter >> breakpointsForModel [

	^ Breakpoint all
]

{ #category : #presenters }
BreakpointBrowserPresenter >> buildTableData [
	self resetAll.
	super buildTableData 
]

{ #category : #presenters }
BreakpointBrowserPresenter >> configureSourceCodeUpdate [

	methodsWithBreakpoints whenSelectionChangedDo: [ :selection | 
		selection isEmpty ifFalse: [ 
			| selectedItem selectedBreakpoint |
			selectedItem := selection selectedItem.
			selectedBreakpoint := selectedItem breakpoint.
			methodsToNodesMap := selectedBreakpoint targetMethodsToNodesMap.

			breakpointedMethods items:
				((SortedCollection sortBlock: [ :a :b | 
						  a methodClass name < b methodClass name ])
					 addAll: methodsToNodesMap keys;
					 yourself).

			breakpointedMethods items isEmpty ifFalse: [ 
				breakpointedMethods selectIndex: 1 ] ] ].

	breakpointedMethods whenSelectionChangedDo: [ :selection | 
		selection isEmpty
			ifTrue: [ breakpointsInSourceCode text: '' ]
			ifFalse: [ 
				| selectedItem |
				selectedItem := selection selectedItem.

				methodsWithBreakpoints selection ifNotNil: [ 
					:selectedBreakpointItem | 
					breakpointsInSourceCode withLineNumbers.
					selectedBreakpointItem selectedItem updateSourceCodePaneFor: self ].
				breakpointsInSourceCode text: selectedItem sourceCode.
				(methodsToNodesMap at: selectedItem) do: [ :node | 
					breakpointsInSourceCode addTextSegmentDecoration:
						(SpTextPresenterDecorator new
							 highlightColor: (Color orange alpha: 0.5);
							 underlineColor: (Color white alpha: 0);
							 interval: (node start to: node stop + 1);
							 yourself) ] ] ]
]

{ #category : #initialization }
BreakpointBrowserPresenter >> initializeBreakpointedMethodsList [

	breakpointedMethods := self newList.
	breakpointedMethods display: [ :compiledMethod | compiledMethod name ]
]

{ #category : #initialization }
BreakpointBrowserPresenter >> initializePresenters [ 
	self buildSourceCode.
	self buildHaltAndBreakpointTable.
	self initializeBreakpointedMethodsList.	
	self configureSourceCodeUpdate.
	self buildTableData.

	SystemAnnouncer uniqueInstance weak when: StHaltCacheChanged send: #buildTableData to: self.
	SystemAnnouncer uniqueInstance weak when: BreakpointAdded send: #buildTableData to: self.
	SystemAnnouncer uniqueInstance weak when: BreakpointRemoved send: #updateBreakpointRemoved: to: self
]

{ #category : #updating }
BreakpointBrowserPresenter >> initializeWindow: aWindowPresenter [
	
	aWindowPresenter
		title: 'Breakpoint Navigator';		
		windowIcon: (self application iconNamed: #glamorousBug)
]

{ #category : #presenters }
BreakpointBrowserPresenter >> resetAll [

	breakpointedMethods items: OrderedCollection new.
	breakpointsInSourceCode text: ''.
	methodsWithBreakpoints unselectAll
]

{ #category : #updating }
BreakpointBrowserPresenter >> updateBreakpointRemoved: aBreakpointAnnouncement [

	| bpItem |
	bpItem := self methodsWithBreakpoints items
		          detect: [ :e | 
		          e breakpoint == aBreakpointAnnouncement breakpoint ]
		          ifNone: [ ^ self ].
	self methodsWithBreakpoints items remove: bpItem.
	self methodsWithBreakpoints refresh.
	self resetAll.
]

{ #category : #updating }
BreakpointBrowserPresenter >> updateSourceCodeForHaltItem: aStHaltInspectionItem [

	breakpointsInSourceCode beForBehavior:
		aStHaltInspectionItem breakpoint node methodNode method methodClass
]

{ #category : #updating }
BreakpointBrowserPresenter >> updateSourceCodeForVariableBreakpointItem: aStBreakpointInspectionItem [

	breakpointsInSourceCode beForBehavior:
		aStBreakpointInspectionItem breakpoint targetClassOrMethod
]