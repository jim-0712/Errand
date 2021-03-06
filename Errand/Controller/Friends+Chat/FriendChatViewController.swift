//
//  FriendChatViewController.swift
//  Errand
//
//  Created by Jim on 2020/2/17.
//  Copyright © 2020 Jim. All rights reserved.
//

import UIKit
import Photos
import Firebase
import MessageKit
import Kingfisher
import InputBarAccessoryView
import FirebaseFirestore

class FriendChatViewController: MessagesViewController {
  
  var chatRoom: Friends?
  
  var reverseUID: String?
  
  var reversePhoto: String?
  
  var selfSender: String?
  
  var personPhoto = ""
  
  var receiver = ""
  
  private var messages: [Message] = []
  
  private var messageListener: ListenerRegistration?
  
  private let dbF = Firestore.firestore()
  
  private var reference: CollectionReference?
  
  private let storage = Storage.storage().reference()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    preSetUp()
    setUpListener()
    setUpMessage()
    navigationItem.setHidesBackButton(true, animated: true)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Icons_24px_Back02"), style: .plain, target: self, action: #selector(backToList))
    navigationItem.leftBarButtonItem?.tintColor = .white
  }
  
  @objc func backToList() {
    self.navigationController?.popViewController(animated: true)
  }
  
  func preSetUp() {
    guard let userInfo = UserManager.shared.currentUserInfo,
      let reverse = reverseUID  else { return }
    AppSettings.displayName = userInfo.nickname
    selfSender = userInfo.uid
    receiver = reverse
  }
  
  func setUpListener() {
    guard let chatRoom = chatRoom else { return }
    reference = dbF.collection(["Chatrooms", chatRoom.chatRoomID, "thread"].joined(separator: "/"))
    messageListener = reference?.addSnapshotListener { querySnapshot, error in
      guard let snapshot = querySnapshot else {
        print("Error listening for channel updates: \(error?.localizedDescription ?? "No error")")
        return
      }
      snapshot.documentChanges.forEach { change in
        self.handleDocumentChange(change)
      }
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
    
    let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
    let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
    
    messagesCollectionView.reloadData()
    
    if shouldScrollToBottom {
      DispatchQueue.main.async {
        self.messagesCollectionView.scrollToBottom(animated: true)
      }
    }
  }
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard let message = Message(document: change.document) else {
      
      return
    }
    
    switch change.type {
    case .added:
      
      insertNewMessage(message)
      
    default:
      break
    }
  }
}

extension FriendChatViewController: MessagesDataSource {
  func currentSender() -> SenderType {
    
    guard let sender = selfSender else { return Sender(id: "", displayName: "")}
    
    return Sender(id: sender, displayName: AppSettings.displayName)
  }
  
  func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
    return messages.count
  }
  
  func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
    return messages[indexPath.section]
  }
  
  func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 18
  }
  
  func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
    
    return NSAttributedString(string: message.sender.displayName, attributes: [.font: UIFont.systemFont(ofSize: 12)])
  }
  
  func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
    
    guard let revesePhoto = reversePhoto,
      let currentUser = UserManager.shared.currentUserInfo else { return }
    
    if message.sender.senderId == currentUser.uid {
      avatarView.loadImage(currentUser.photo, placeHolder: UIImage(named: "photographer"))
    } else {
      avatarView.loadImage(revesePhoto, placeHolder: UIImage(named: "photographer"))
    }
  }
}

extension FriendChatViewController: MessagesLayoutDelegate {
  
  func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return CGSize(width: 100, height: 100)
  }
  
  func footerViewSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
    return CGSize(width: 0, height: 8)
  }
  
  func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
    return 0
  }
}

extension FriendChatViewController: MessagesDisplayDelegate {
  
  func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return isFromCurrentSender(message: message) ? UIColor.lightGray  : .incomingMessage
  }
  
  func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
    return .darkGray
  }
  
  func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
    return false
  }
  
  func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
    
    let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
    return .bubbleTail(corner, .pointedEdge)
  }
}

extension FriendChatViewController: MessageInputBarDelegate {
  
  @objc func tapSend() {
    
    guard let text = messageInputBar.inputTextView.text,
      let user = Auth.auth().currentUser else { return }
    
    if let photo = Auth.auth().currentUser?.photoURL {
      
      personPhoto = "\(photo)"
    } else {
      
      personPhoto = ""
    }
    
    let message = Message(user: user, content: text, photo: personPhoto)
    save(message)
    messageInputBar.inputTextView.resignFirstResponder()
    self.view.endEditing(true)
    messageInputBar.inputTextView.text = ""
  }
}
