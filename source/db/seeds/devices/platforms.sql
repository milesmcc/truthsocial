insert into		"devices"."platforms" (
				"platform_id",
				"name"
			)
	values		(
				1,
				'iOS'
			),
			(
				2,
				'Android'
			)
	on		conflict
		do	nothing;
