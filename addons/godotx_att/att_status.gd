class_name ATTStatus
extends RefCounted

enum Status {
	NOT_DETERMINED = 0,
	RESTRICTED = 1,
	DENIED = 2,
	AUTHORIZED = 3,
}

const NOT_DETERMINED := Status.NOT_DETERMINED
const RESTRICTED := Status.RESTRICTED
const DENIED := Status.DENIED
const AUTHORIZED := Status.AUTHORIZED


static func status_to_string(status: int) -> String:
	match status:
		Status.NOT_DETERMINED:
			return "not_determined"
		Status.RESTRICTED:
			return "restricted"
		Status.DENIED:
			return "denied"
		Status.AUTHORIZED:
			return "authorized"
		_:
			return "unknown"


static func is_trackable(status: int) -> bool:
	return status == Status.AUTHORIZED
