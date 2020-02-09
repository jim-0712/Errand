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
import FirebaseFirestore

class ChatViewController: MessagesViewController {
  
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    preSetUp()
  }
  
  var detailData: TaskInfo?
  
  var selfSender: String?
  
  var receiver: String?
  
  private let user: User
  private let channel: Channel
  
  init(user: User, channel: Channel) {
    self.user = user
    self.channel = channel
    super.init(nibName: nil, bundle: nil)
    
    title = channel.name
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
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
    messageInputBar.delegate = self
    messagesCollectionView.messagesDataSource = self
    messagesCollectionView.messagesLayoutDelegate = self
    messagesCollectionView.messagesDisplayDelegate = self
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
  
  func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 12
  }
  
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
    
    let message = Message(user: user, content: text)
//    save(message)
    inputBar.inputTextView.text = ""
  }
}
