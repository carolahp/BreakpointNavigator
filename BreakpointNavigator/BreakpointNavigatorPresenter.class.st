"
I browse halts and breakpoints of the system.
I add and fix problems of `StDebuggerBreakpointInspection`, and I should later be merged with it.
"
Class {
	#name : #BreakpointNavigatorPresenter,
	#superclass : #StDebuggerBreakpointInspection,
	#instVars : [
		'breakpointedMethods',
		'methodsToNodesMap',
		'breakpointsHeader',
		'methodsHeader',
		'codeHeader'
	],
	#category : #BreakpointNavigator
}

{ #category : #extensions }
BreakpointNavigatorPresenter class >> breakpointCommandsWith: presenter forRootGroup: aCmCommandsGroup [
	<extensionCommands>
	
	aCmCommandsGroup
		register: (self removeBreakpointCommandFor: presenter);
		register: (self browseBreakpointMethodCommandFor: presenter)
]

{ #category : #'world menu' }
BreakpointNavigatorPresenter class >> menuCommandOn: aBuilder [

	<worldMenu>
	(aBuilder item: #'Breakpoint Navigator')
		parent: #Debug;
		action: [ self new open ];
		order: -1;
		help:
			'A breakpoint navigator that allows you to browse, uninstall and (de)activate breakpoints at will.';
		icon: (self iconNamed: #glamorousBug).
	aBuilder withSeparatorAfter
]

{ #category : #extensions }
BreakpointNavigatorPresenter class >> removeBreakpointCommandFor: presenter [
	| cmd |
	cmd := BreakpointNavigatorRemoveBreakpointCommand forSpecContext: presenter.
	cmd iconName: #smallDelete.
	cmd innerCommand
		transform: [ :ctx | ctx methodsWithBreakpoints selection selectedItem ].
	^ cmd
]

{ #category : #private }
BreakpointNavigatorPresenter >> breakpointsForModel [

	^ Breakpoint all
]

{ #category : #presenters }
BreakpointNavigatorPresenter >> buildTableData [
	self resetAll.
	super buildTableData 
]

{ #category : #presenters }
BreakpointNavigatorPresenter >> configureSourceCodeUpdate [

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
BreakpointNavigatorPresenter >> initializeBreakpointedMethodsList [

	breakpointedMethods := self newList.
	breakpointedMethods display: [ :compiledMethod | compiledMethod name ]
]

{ #category : #initialization }
BreakpointNavigatorPresenter >> initializeHeaders [

	breakpointsHeader := self instantiate: StHeaderBar.
	breakpointsHeader label: 'Breakpoints'.
	methodsHeader := self instantiate: StHeaderBar.
	methodsHeader label: 'Affected methods'.
	codeHeader := self instantiate: StHeaderBar.
	codeHeader label: 'Breakpoint locations in the source code'.
]

{ #category : #initialization }
BreakpointNavigatorPresenter >> initializePresenters [ 
	self initializeHeaders.
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
BreakpointNavigatorPresenter >> initializeWindow: aWindowPresenter [
	
	aWindowPresenter
		title: 'Breakpoint Navigator';		
		windowIcon: (self application iconNamed: #glamorousBug);
		initialExtent: 800@400
]

{ #category : #presenters }
BreakpointNavigatorPresenter >> resetAll [

	breakpointedMethods items: OrderedCollection new.
	breakpointsInSourceCode text: ''.
	methodsWithBreakpoints unselectAll
]

{ #category : #updating }
BreakpointNavigatorPresenter >> updateBreakpointRemoved: aBreakpointAnnouncement [

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
BreakpointNavigatorPresenter >> updateSourceCodeForHaltItem: aStHaltInspectionItem [

	breakpointsInSourceCode beForBehavior:
		aStHaltInspectionItem breakpoint node methodNode method methodClass
]

{ #category : #updating }
BreakpointNavigatorPresenter >> updateSourceCodeForVariableBreakpointItem: aStBreakpointInspectionItem [

	breakpointsInSourceCode beForBehavior:
		aStBreakpointInspectionItem breakpoint targetClassOrMethod
]