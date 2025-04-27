insert into		"geography"."cities" (
				"name",
				"region_id"
			)
	values		(
				'Unknown',
				"geography"."region_id" (
					'??',
					'??'
				)
			)
	on		conflict
		do	nothing;
