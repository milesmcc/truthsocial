insert into		"feeds"."feeds" (
				"name",
				"description",
				"visibility",
				"feed_type",
				"created_by_account_id"
			)
	values		(
				'Following',
				'A chronological timeline of Truths from accounts you follow.',
				'public',
				'following',
				-99
			),
			(
				'For You',
				'Truths we think you''ll be interested in',
				'public',
				'for_you',
				-99
			),
			(
				'Groups',
				'A chronological timeline of Truths from the Groups you''ve joined.',
				'public',
				'groups',
				-99
			)
	on		conflict
		do	nothing;
