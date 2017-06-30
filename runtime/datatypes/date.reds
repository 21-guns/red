Red/System [
	Title:	 "Date! datatype runtime functions"
	Author:	 "Nenad Rakocevic"
	File: 	 %date.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

date: context [
	verbose: 0

	#define GET_YEAR(date)   (date >> 16)
	#define GET_MONTH(date) (date >> 12 and 0Fh)
	#define GET_DAY(date) (date >> 7 and 1Fh)
	#define GET_TIMEZONE(date) (date and 7Fh)

	#define DATE_GET_YEAR(d)	(d >> 16)
	#define DATE_GET_MONTH(d)	((d >> 12) and 0Fh)
	#define DATE_GET_DAY(d)		((d >> 7) and 1Fh)
	#define DATE_GET_HOURS(t)   (floor t / time/h-factor)
	#define DATE_GET_MINUTES(t) (floor t / time/oneE9 // 3600.0 / 60.0)
	#define DATE_GET_SECONDS(t) (t / time/oneE9 // 60.0)
	
	push-field: func [
		dt		[red-date!]
		field	[integer!]
		return: [red-value!]
		/local
			d [integer!]
			t [float!]
	][
		d: dt/date
		t: dt/time
		as red-value! switch field [
			1 [integer/push DATE_GET_YEAR(d)]
			2 [integer/push DATE_GET_MONTH(d)]
			3 [integer/push DATE_GET_DAY(d)]
			5 [time/push t]
			6 [integer/push as-integer DATE_GET_HOURS(t)]
			7 [integer/push as-integer DATE_GET_MINUTES(t)]
			8 [float/push DATE_GET_SECONDS(t)]
			default [assert false]
		]
	]
	
	box: func [
		year	[integer!]
		month	[integer!]
		day		[integer!]
		return: [red-date!]
		/local
			dt	[red-date!]
	][
		dt: as red-date! stack/arguments
		dt/header: TYPE_DATE
		dt/date: (year << 16) or (month << 12) or (day << 7)
		dt/time: 0.0
		dt
	]

	days-to-date: func [
		days	[integer!]
		return: [integer!]
		/local
			y	[integer!]
			m	[integer!]
			d	[integer!]
			dd [integer!]
			mi	[integer!]
	][
		y: 10000 * days + 14780 / 3652425
		dd: days - (365 * y + (y / 4) - (y / 100) + (y / 400))
		if dd < 0 [
			y: y - 1
			dd: days - (365 * y + (y / 4) - (y / 100) + (y / 400))
		]
		mi: 100 * dd + 52 / 3060
		m: mi + 2 % 12 + 1
		y: y + (mi + 2 / 12)
		d: dd - (mi * 306 + 5 / 10) + 1
		y << 16 or (m << 12) or (d << 7)
	]

	date-to-days: func [
		date	[integer!]
		return: [integer!]
		/local
			y	[integer!]
			m	[integer!]
			d	[integer!]
	][
		y: GET_YEAR(date)
		m: GET_MONTH(date)
		d: GET_DAY(date)
		365 * y + (y / 4) - (y / 100) + (y / 400) + ((m * 306 + 5) / 10) + (d - 1)
	]

	get-utc-time: func [
		tm		[float!]
		tz		[integer!]
		return: [float!]
		/local
			m	[integer!]
			h	[integer!]
			hh	[float!]
			mm	[float!]
	][
		h: tz << 25 >> 27		;-- keep signed
		m: tz and 03h * 15
		hh: (as float! h) * time/h-factor
		mm: (as float! m) * time/m-factor
		tm + hh + mm
	]

	;-- Actions --

	make: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
		/local
			value [red-value!]
			tail  [red-value!]
			v	  [red-value!]
			int	  [red-integer!]
			fl	  [red-float!]
			year  [integer!]
			month [integer!]
			day   [integer!]
			idx   [integer!]
			i	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/make"]]
		
		if TYPE_OF(spec) = TYPE_DATE [return spec]
		year:   0
		month:  1
		day:    1
		
		switch TYPE_OF(spec) [
			TYPE_BLOCK [
				value: block/rs-head as red-block! spec
				tail:  block/rs-tail as red-block! spec
				
				idx: 1
				while [value < tail][
					v: either TYPE_OF(value) = TYPE_WORD [
						_context/get as red-word! value
					][
						value
					]
					switch TYPE_OF(v) [
						TYPE_INTEGER [
							int: as red-integer! v
							i: int/value
						]
						TYPE_FLOAT [
							fl: as red-float! v
							i: as-integer fl/value
						]
						default [0]						;@@ fire error
					]
					switch idx [1 [year: i] 2 [month: i] 3 [day: i]]
					idx: idx + 1
					value: value + 1
				]
			]
			default [0]									;@@ fire error
		]
		as red-value! box year month day
	]
		
	form: func [
		dt		[red-date!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/form"]]
		
		mold dt buffer no no no arg part 0
	]
	
	mold: func [
		dt		[red-date!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
			blk	   [red-block!]
			month  [red-string!]
			len	   [integer!]
			d	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/mold"]]
		
		d: dt/date
		formed: integer/form-signed DATE_GET_DAY(d)
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #"-"
		
		blk: as red-block! #get system/locale/months
		month: as red-string! (block/rs-head blk) + DATE_GET_MONTH(d) - 1
		;if month > block/rs-tail [...]					;@@ fire error
		;if TYPE_OF(month) <> TYPE_STRING [...]			;@@ fire error
		
		string/concatenate buffer month 3 0 yes no
		part: part - 4									;-- 3 + separator
		
		string/append-char GET_BUFFER(buffer) as-integer #"-"
		
		formed: integer/form-signed DATE_GET_YEAR(d)
		string/concatenate-literal buffer formed
		len: 4 - length? formed
		if len > 0 [loop len [string/append-char GET_BUFFER(buffer) as-integer #"0"]]
		part: part - 5									;-- 4 + separator
		
		if dt/time <> 0.0 [
			string/append-char GET_BUFFER(buffer) as-integer #"/"
			part: time/mold as red-time! dt buffer only? all? flat? arg part - 1 indent
		]
		part
	]

	do-math: func [
		type	  [integer!]
		return:	  [red-date!]
		/local
			left  [red-date!]
			right [red-date!]
			int   [red-integer!]
			tm	  [red-time!]
			days  [integer!]
			tz	  [integer!]
			ft	  [float!]
			d	  [integer!]
			dd	  [integer!]
			tt	  [float!]
			h	  [float!]
			word  [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/do-math"]]
		left:  as red-date! stack/arguments
		right: as red-date! left + 1

		switch TYPE_OF(right) [
			TYPE_INTEGER [
				int: as red-integer! right
				dd: int/value
				tt: 0.0
			]
			TYPE_TIME [
				tm: as red-time! right
				dd: 0
				tt: tm/time
			]
			TYPE_DATE [
				dd: date-to-days right/date
				tt: right/time
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]

		h: tt / time/h-factor
		d: (as-integer h) / 24
		h: as float! d
		tt: tt - (h * time/h-factor)
		dd: dd + d

		tz: GET_TIMEZONE(left/date)
		days: date-to-days left/date
		ft: left/time
		switch type [
			OP_ADD [
				days: days + dd
				ft: ft + tt
			]
			OP_SUB [
				days: days - dd
				ft: ft - tt
			]
			default [0]
		]
		left/date: tz or days-to-date days
		left/time: ft
		left
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "date/add"]]
		as red-value! do-math OP_ADD
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "date/subtract"]]
		as red-value! do-math OP_ADD
	]

	eval-path: func [
		dt		[red-date!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			word   [red-word!]
			int	   [red-integer!]
			fl	   [red-float!]
			tm	   [red-time!]
			field  [integer!]
			sym	   [integer!]
			v	   [integer!]
			d	   [integer!]
			fval   [float!]
			error? [logic!]
	][
		error?: no

		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				field: int/value
				if any [field < 1 field > 5][error?: yes]
			]
			TYPE_WORD [
				word: as red-word! element
				sym: symbol/resolve word/symbol
				case [
					sym = words/year   [field: 1]
					sym = words/month  [field: 2]
					sym = words/day	   [field: 3]
					sym = words/zone   [field: 4]
					sym = words/time   [field: 5]
					sym = words/hour   [field: 6]
					sym = words/minute [field: 7]
					sym = words/second [field: 8]
					sym = words/weekday[field: 9]
					sym = words/julian [field: 10]
					true 			   [error?: yes]
				]
			]
			default [error?: yes]
		]
		if error? [fire [TO_ERROR(script invalid-path) stack/arguments element]]

		either value <> null [
			if all [1 <= field field <= 3][
				if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
				int: as red-integer! value
				v: int/value
			]
			if all [6 <= field field <= 8][
				return time/eval-path as red-time! dt element value path case?
			]
			d: dt/date
			switch field [
				1 [dt/date: d and FFFFh or (v << 16)]
				2 [if v <= 0 [v: 12 + v] dt/date: d and FFFF0FFFh or (v and 0Fh << 12)]
				3 [if v <= 0 [v: 31 + v] dt/date: d and FFFE0FFFh or (v and 1Fh << 7)]
				5 [
					either TYPE_OF(value) = TYPE_TIME [
						tm: as red-time! value
						dt/time: tm/time
					][
						return time/eval-path as red-time! dt element value path case?
					]
				]
				default [assert false]
			]
			value
		][
			value: push-field dt field
			stack/pop 1									;-- avoids moving stack up
			value
		]
	]
	
	init: does [
		datatype/register [
			TYPE_DATE
			TYPE_VALUE
			"date!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			null			;compare
			;-- Scalar actions --
			null			;absolute
			:add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			:subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]