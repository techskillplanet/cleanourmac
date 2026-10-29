import 'dart:convert';

class FcmDemoPayload {
  static const placeholderToken =
      'REPLACE_WITH_DEVICE_FCM_TOKEN_PLACEHOLDER_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

  static Map<String, dynamic> simpleNotification() => {
    'token': placeholderToken,
    'notification': {
      'title': '欢迎使用 Firebase 推送调试',
      'body': '这是一条演示消息，请替换为真实设备 token 后再发送',
      'image':
          'https://img2.baidu.com/it/u=1010328615,2032873142&fm=253&fmt=auto&app=120&f=JPEG?w=1200&h=790',
    },
    'data': {
      'jumpType': '3',
      'richMediaType': '1',
      'templateInfoType': '9',
      'title': '欢迎使用Firebase推送 前台',
      'content': '这是一条演示消息，展示推送通知功能 前台',
      'jumpUrl': 'https://github.com',
      'subtitle': '演示通知',
      'showType': '1',
      'category': 'demo',
    },
    'android': {
      'notification': {'sound': 'default'},
    },
  };

  static String fullJsonTemplate() {
    final message = Map<String, dynamic>.from(simpleNotification());
    return const JsonEncoder.withIndent('  ').convert({'message': message});
  }
}
