insert into		"geography"."regions" (
				"code",
				"name",
				"country_id"
			)
	values		(
				'??',
				'Unknown',
				"geography"."country_id" ('??')
			)
	on		conflict
		do	nothing;
