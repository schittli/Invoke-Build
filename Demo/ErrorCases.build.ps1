
<#
.Synopsis
	Tests various runtime errors.
#>

# Import tasks Error1 and Error2 (dot-sourced because imported with data).
. .\SharedTasksData.tasks.ps1

# This task is prepared to survive on errors in Error1 and Error2. It would
# survive if it is called alone. But it fails because the error in Error2 is
# going to break the task Fails and the build anyway. So it all fails fast.
task AlmostSurvives @(
	# Tells to call the task Error1 and ignore its failure
	@{Error1=1},
	# Code invoked after the task Error1
	{
		"After Error1 -- this works"
	},
	# Tells to call the task Error2 and ignore its failure
	@{Error2=1},
	# This code is not going to be invoked
	{
		"After Error2 -- this is not called"
	}
)

# This task is prepared for errors in Error1, that is why build continues after
# the first error in the task AlmostSurvives. But this task is not prepared for
# errors in Error2, that is why the whole build fails. Note: it does not matter
# that the downstream task calls this as @{Fails=1}, the task Fails is not
# ready for errors in Error2 (otherwise it would call it as @{Error2=1}).
task Fails @(
	@{Error1=1},
	{},
	# This unprotected reference makes the build to fail.
	# IMPORTANT: This task Fails is not even get called.
	'Error2'
	{}
)

# This task calls the tests and fails due to issues in the Fails. Even
# protected call does not help: Fails is not prepared for errors in Error2.
task TestAlmostSurvives AlmostSurvives, @{Fails=1}

# Error: the If script fails.
task ScriptConditionFails -If { throw "If fails." } { throw }

# Error: the inputs script fails.
task IncrementalInputsFails -Incremental @{{ throw 'Incremental inputs fails.' } = {}} { throw }
task PartialInputsFails -Partial @{{ throw 'Partial inputs fails.' } = {}} { throw }

# Error: the outputs script fails.
task IncrementalOutputsFails -Incremental @{{ '.build.ps1' } = { throw 'Incremental outputs fails.' }} { throw }
task PartialOutputsFails -Partial @{{ '.build.ps1' } = { throw 'Partial outputs fails.' }} { throw }

# Error: incremental output is empty
# Error: partial inputs and outputs have different number of items
task IncrementalOutputsIsEmpty -Incremental @{{ '.build.ps1' } = {}} { throw }
task InputsOutputsMismatch -Partial @{{ '.build.ps1' } = {}} { throw }

# Error: one of the input items is missing.
task IncrementalMissingInputs -Incremental @{{ 'missing' } = {}} { throw }
task PartialMissingInputs -Partial @{{ 'missing' } = {}} { throw }

# Error: missing property
task MissingProperty {
	$MissingProperty = property MissingProperty
}
