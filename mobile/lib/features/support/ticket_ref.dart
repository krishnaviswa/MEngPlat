/// Short public ticket reference: `MH-` plus the first 8 characters of the UUID, uppercased.
String supportTicketRef(String id) {
  final take = id.length >= 8 ? id.substring(0, 8) : id;
  return 'MH-${take.toUpperCase()}';
}
