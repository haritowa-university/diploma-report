func getDevices(for userID: String) 
	-> Observable<List<DeviceModel>?> {
    let realmQuery = DB.mainThreadRealm
	    .objects(UserModel.self)
	    .filter("id = '\(userID)'")

    return Observable.array(from: realmQuery).map {
        guard let user = users.first else { return nil }
        return user.devices
    }
}