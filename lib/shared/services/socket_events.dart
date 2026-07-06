class SocketEvents {
  // Del Cliente al Servidor
  static const String clientJoin = "record:join";
  static const String clientLockField = "field:lock";
  static const String clientUnlockField = "field:unlock";
  static const String clientUpdateField = "field:update";

  // Del Servidor al Cliente
  static const String serverSyncState = "record:sync";
  static const String serverFieldLocked = "field:locked";
  static const String serverFieldUnlocked = "field:unlocked";
  static const String serverFieldUpdated = "field:updated";
  static const String serverError = "server:error";
}
