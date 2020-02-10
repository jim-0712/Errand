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
import Kingfisher
import InputBarAccessoryView
import FirebaseFirestore

class ChatViewController: MessagesViewController {
  
  var personPhoto = ""
  
  private var messages: [Message] = []
  private var messageListener: ListenerRegistration?
  
  private let db = Firestore.firestore()
  private var reference: CollectionReference?
  
  private var isSendingPhoto = false
  //  {
  //    didSet {
  //      DispatchQueue.main.async {
  //        self.messageInputBar.leftStackViewItems.forEach { item in
  //          item.isEnable  = !self.isSendingPhoto
  //        }
  //      }
  //    }
  //  }
  
  private let storage = Storage.storage().reference()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setUpListener()
    setUpMessage()
    preSetUp()
    setUpCamera()
  }
  
  func setUpListener() {
    guard let data = detailData else { return }
    reference = db.collection(["Chatrooms", data.chatRoom, "thread"].joined(separator: "/"))
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
  
  var detailData: TaskInfo?
  
  var selfSender: String?
  
  var receiver: String?
  
  var counter = 0
  
  var receiverPhoto: String = ""
  
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
  
  private func uploadImage(_ image: UIImage, to channel: String, completion: @escaping (URL?) -> Void) {
    
    guard let scaledImage = image.scaledToSafeUploadSize,
      let data = scaledImage.jpegData(compressionQuality: 0.4) else {
        completion(nil)
        return
    }
    
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    
    let imageName = [UUID().uuidString, String(Date().timeIntervalSince1970)].joined()
    
    let storageRef = storage.storage.reference().child(channel).child(imageName)
    storageRef.putData(data, metadata: metadata) { _, error in
      
      storageRef.downloadURL { (url, error) in
        
        if error != nil { return }
        
        guard let urlBack = url else { return }
        
        completion(urlBack)
        
      }
    }
  }
  
  private func sendPhoto(_ image: UIImage) {
    isSendingPhoto = true
    
    guard let task = detailData else { return }
    
    uploadImage(image, to: task.chatRoom) { [weak self] url in
      guard let strongSelf = self else {
        return
      }
      strongSelf.isSendingPhoto = false
      
      guard let url = url else {
        return
      }
      
      guard let user = Auth.auth().currentUser else { return }
      if let photo = Auth.auth().currentUser?.photoURL {
        
        strongSelf.personPhoto = "\(photo)"
      } else {
        
        strongSelf.personPhoto = ""
      }
    
      var message = Message(user: user, image: image, personPhoto: strongSelf.personPhoto)
      message.downloadURL = url
      
      strongSelf.save(message)
      strongSelf.messagesCollectionView.scrollToBottom()
    }
  }
  
  @objc private func cameraButtonPressed() {
    let picker = UIImagePickerController()
    picker.delegate = self
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      picker.sourceType = .camera
    } else {
      picker.sourceType = .photoLibrary
    }
    
    present(picker, animated: true, completion: nil)
  }
  
  func setUpCamera() {
    let cameraItem = InputBarButtonItem(type: .system)
    cameraItem.tintColor = .primary
    cameraItem.image = UIImage(named: "drive")
    // 2
    cameraItem.addTarget(
      self,
      action: #selector(cameraButtonPressed),
      for: .primaryActionTriggered
    )
    cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
    
    messageInputBar.leftStackView.alignment = .center
    messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
    // 3
    messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false)
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
  
  private func handleDocumentChange(_ change: DocumentChange) {
    guard var message = Message(document: change.document) else {
      
      return
    }
    
    switch change.type {
    case .added:
      if let url = message.downloadURL {
        
        if let imageData = NSData(contentsOf: url) as Data? {
          message.image = UIImage(data: imageData)
          insertNewMessage(message)
        }
        
//        downloadImage(at: url) { [weak self] image in
//          guard let strongSelf = self else { return }
//          message.image =
//          message.image = image
//          strongSelf.insertNewMessage(message)
//        }
      } else {
        
        insertNewMessage(message)
      }
      
    default:
      break
    }
  }
  
  private func downloadImage(at url: URL, completion: @escaping (UIImage?) -> Void) {
    let ref = Storage.storage().reference(forURL: url.absoluteString)
    let megaByte = Int64(1 * 1024 * 1024)
    
    ref.getData(maxSize: megaByte) { data, error in
      guard let imageData = data else {
        completion(nil)
        return
      }
      
      completion(UIImage(data: imageData))
    }
  }
}

extension ChatViewController: MessagesDataSource {
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
    
    //    message.
    
    //    UserManager.shared.readData(uid: message.sender.senderId) { result in
    //
    //      switch result {
    //
    //      case .success(let userInfo):
    //
    //        avatarView.loadImage(userInfo.photo, placeHolder: UIImage(named: "develop"))
    //
    //      case .failure(let error):
    //
    //        print(error.localizedDescription)
    //      }
    
    //    }
  }
}

extension ChatViewController: MessagesLayoutDelegate {
  
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
  
  @objc func tapSend() {
    
    guard let text = messageInputBar.inputTextView.text,
      let user = Auth.auth().currentUser else { return }
    
    if let photo = Auth.auth().currentUser?.photoURL {
      
      personPhoto = "\(photo)"
    } else {
      
      personPhoto = ""
    }
    
    let message = Message(user: user, content: text, personPhoto: personPhoto)
    save(message)
    messageInputBar.inputTextView.resignFirstResponder()
    self.view.endEditing(true)
    messageInputBar.inputTextView.text = ""
  }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
   
    if let image = info[.originalImage] as? UIImage { // 2
      picker.dismiss(animated: true, completion: nil)
      sendPhoto(image)
    }
  }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
  
}
