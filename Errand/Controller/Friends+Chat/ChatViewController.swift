//
//  ChatViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/8.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Photos
import Firebase
import MessageKit
import InputBarAccessoryView
import FirebaseFirestore

class ChatViewController: MessagesViewController {
  
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  private let db = Firestore.firestore()
  private var reference: CollectionReference?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpMessage()
    preSetUp()
    
    guard let data = detailData else { return }
    reference = db.collection(["Chatrooms", data.chatRoom, "thread"].joined(separator: "/"))
//    guard let user = Auth.auth().currentUser else { return }
//
//    let testMessage = Message(user: user, content: "I love pizza, what is your favorite kind?")
//    insertNewMessage(testMessage)
  }
  
  var detailData: TaskInfo?
  
  var selfSender: String?
  
  var receiver: String?

  func preSetUp() {
    guard let userInfo = UserManager.shared.currentUserInfo,
      let taskData = detailData  else { return }
    AppSettings.displayName = userInfo.nickname
    if userInfo.status == 1 {
      selfSender = userInfo.uid
      receiver = taskData.missionTaker
    } else {
      selfSender = userInfo.uid
      receiver = taskData.uid
    }
  }
  
  func setUpMessage() {
    navigationItem.largeTitleDisplayMode = .never
    maintainPositionOnKeyboardFrameChanged = true
    messageInputBar.inputTextView.tintColor = .primary
    messageInputBar.sendButton.setTitleColor(.primary, for: .normal)
    messageInputBar.sendButton.addTarget(self, action: #selector(tapSend), for: .touchUpInside)
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
  }
  
  private func save(_ message: Message) {
    reference?.addDocument(data: message.representation) { error in
      if let eccc = error {
        print("Error sending message: \(eccc.localizedDescription)")
        return
      }
      self.messagesCollectionView.scrollToBottom()
    }
  }
  
  private func insertNewMessage(_ message: Message) {
    guard !messages.contains(message) else {
      return
    }
    
    messages.append(message)
    messages.sort()
    
    let isLatestMessage = messages.index(of: message) == (messages.count - 1)
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      DispatchQueue.main.async {
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }
  
}

extension ChatViewController: MessagesDataSource {
  func currentSender() -> SenderType {
    
    guard let sender = selfSender else { return Sender(senderId: "", displayName: "")}
    
    return Sender(id: sender, displayName: AppSettings.displayName)
  }
  
  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return messages[indexPath.section]
  }
  
//  func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
//    return 12
//  }
//
  func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    
    return NSAttributedString(string: message.sender.displayName, attributes: [.font: UIFont.systemFont(ofSize: 12)])
  }
}

extension ChatViewController: MessagesLayoutDelegate {
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return .zero
  }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return CGSize(width: 0, height: 8)
  }
  
  func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 0
  }
}

extension ChatViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? .primary : .incomingMessage
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
    return false
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    return .bubbleTail(corner, .curved)
  }
}

extension ChatViewController: MessageInputBarDelegate {
  
  func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
    print("1")
    
    guard let user = Auth.auth().currentUser else { return }
    
    let message = Message(user: user, content: text)
    save(message)
    inputBar.inputTextView.text = ""
  }
  
  @objc func tapSend() {

    guard let text = messageInputBar.inputTextView.text,
         let user = Auth.auth().currentUser else { return }

    let message = Message(user: user, content: text)
       save(message)
       messageInputBar.inputTextView.resignFirstResponder()
       self.view.endEditing(true)
       messageInputBar.inputTextView.text = ""
  }
}
