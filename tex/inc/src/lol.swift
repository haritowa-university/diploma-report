
import AsyncDisplayKit

protocol HeaderBehavioursCNode: class {
 

 func asNode() -> ASDisplayNode
 

 func asScrollView() -> UIScrollView

 func additionalTopInset() -> CGFloat
}

extension HeaderBehavioursCNode {
 func additionalTopInset() -> CGFloat {
  return 0
 }
}

extension ModulesC: HeaderBehavioursCNode {
 func asNode() -> ASDisplayNode {
  return self.node.asNode()
 }

 func asScrollView() -> UIScrollView {
  return self.node.asScrollView()
 }
}

import AsyncDisplayKit
import GSKStretchyHeaderView

class HeaderC<T: ScreenCData, VM>: ModulesC<T, VM>, ASTableDelegate, 
HICProtocol, ScrollAdjustable where VM: MCVMPR {
 private lazy var C: Coordinator = Coordinator()

 // MARK: - HeaderInjectableModulesC
 func prepareForInjection() {
  C.prepareForInjection()
 }

 func inject(header: GSKStretchyHeaderView?) {
  C.inject(header: header)
 }

 // MARK: - Behaviours
 func behaviours() -> HeaderCBehaviour {
  return .all
 }

 // MARK: Insets
 override func viewDidLoad() {
  super.viewDidLoad()
  setupAdjustsScrollViewInsets()
  node.delegate = self
  C.viewDidLoad()
 }

 // MARK: B
 override func adjustBottomInsets(insets: AdjustedInsets) {
  self.additionalBottomInsets = insets.adjustedInsets
  C.adjustBottomInsets(insets: insets)
 }
}

import Foundation

struct HeaderCBehaviour: OptionSet {
 let rawValue: Int


 static let snap = HeaderCBehaviour(rawValue: 1 << 0)


 static let collapsible = HeaderCBehaviour(rawValue: 1 << 1)


 static let bottomInsetAdjustable = HeaderCBehaviour(rawValue: 1 << 2)


 static let headerTopInsetAdjuster = HeaderCBehaviour(rawValue: 1 << 3)

 static let all: HeaderCBehaviour = [
  .snap,
  .collapsible,
  .bottomInsetAdjustable,
  .headerTopInsetAdjuster
 ]

import Foundation
import GSKStretchyHeaderView

protocol HICProtocol {

 func inject(header: GSKStretchyHeaderView?)



 func prepareForInjection()

import AsyncDisplayKit
import RxSwift
import RxCocoa

import GSKStretchyHeaderView

class LeafStretchyModulesC<VM>: StretchyModulesC<VM>
 where VM: LeafStretchyModulesVMProtocol,
    VM.CData == VM.HeaderVM.CData {
}

import AsyncDisplayKit
import RxSwift
import RxCocoa

class ModulesC<T: ScreenCData, VM>: ASViewController<ASTableNode>, 
 VMI, Y, B where VM: MCVMPR {
 typealias AssociatedVM = VM

 // MARK: - Props
 // MARK: Rx
 let disposeBag = DisposeBag()
 fileprivate(set) var VM: VM!

 // MARK: B
 var additionalBottomInsets: CGFloat = 0

 // MARK: - Init
 init() {
  let table = ASTableNode(style: .plain)
  super.init(node: table)
 }

 required init?(coder aDecoder: NSCoder) {
  fatalError("init(coder:) has not been implemented")
 }

 override func viewDidLoad() {
  super.viewDidLoad()
  node.defaultSetup()
 }

 // MARK: - VMI
 func setup(with VM: VM) {
  self.VM = VM
 }

 func generateInput() -> VM.InitInput {
  return DefaultMCVMI(
    tableNode: node,
    disposeBag: disposeBag
  ) as! VM.InitInput // swiftlint:disable:this force_cast
  // Override if associated view model has different input type
 }

 // MARK: - Y
 func setup(with pallet: YonderPalette) {
  self.navigationController?.navigationBar.barTintColor = pallet.tabBarBG
 }

 // MARK: - B
 func bottomInsetsSubscriptionBag() -> DisposeBag {
  return disposeBag
 }

 func adjustBottomInsets(insets: AdjustedInsets) {
  self.additionalBottomInsets = insets.adjustedInsets

  let prevInsets: UIEdgeInsets = self.node.contentInset
  self.node.contentInset = UIEdgeInsets(
    top: prevInsets.top,
    left: prevInsets.left,
    bottom: self.additionalBottomInsets,
    right: prevInsets.right
  )
 }
}

extension ModulesC: DisposeBagProvider {
 var bag: DisposeBag {
  return disposeBag
 }
}

import Foundation
import RxSwift
import RxCocoa

import AsyncDisplayKit

protocol MCVMI {
 var tableNode: ASTableNode { get }
 var disposeBag: DisposeBag { get }
}

struct DefaultMCVMI: MCVMI {
 let tableNode: ASTableNode
 let disposeBag: DisposeBag
}

protocol MCVMPR: class, LazyVM where InitInput: MCVMI {
 func contextProvider() -> CTXProvider?
 func refreshO() -> O<RefreshDescription>
 func modulesProviderGenerator() -> RXRDS.MPGR
 func RXRDS() -> RXRDS
 

 func rxASDKDataSource() -> RxASDKTableDataSource
}

extension MCVMPR {
 

 ///

 private func createTableFooter(disposeBag: DisposeBag) -> UIView {
  let activityIndicator = UIActivityIndicatorView()
  activityIndicator.startAnimating()
  activityIndicator.color = YonderPalette.current.tabBarBG
  activityIndicator.hidesWhenStopped = false

  YonderPalette.currentPalletO.map { palette -> UIColor in palette.tabBarBG }
    .bind(onNext: { color in activityIndicator?.color = color })
    .disposed(by: disposeBag)

  return activityIndicator
 }


 func bind(to tableNode: ASTableNode, disposeBag: DisposeBag) {
  _bind(to: tableNode, disposeBag: disposeBag)
 }
 
 @discardableResult func _bind(to tableNode: ASTableNode) -> RXRDS {
  let items = RXRDS()
  let dataSource = rxASDKDataSource()

  tableNode.rx.items(dataSource: dataSource, O: items.output)
    .disposed(by: disposeBag)

  let footer = createTableFooter(disposeBag: disposeBag)

  items.isRefreshRunning.observeOn(MainScheduler.instance)
    .bind(onNext: { [weak tableNode] (_, isRunning) in
     guard let tableNode = tableNode else { return }
     if isRunning {
      tableNode.view.tableFooterView = footer
     } else {
      tableNode.view.tableFooterView = UIView()
     }
    }).disposed(by: disposeBag)

  items.input.onNext(refreshO())
  
  return items
 }
}

class AnyModulesCVM<InitInput: MCVMI>: MCVMPR {
 func setup(with input: InitInput) {
  bind(to: input.tableNode, disposeBag: input.disposeBag)
 }

 func refreshO() -> O<RefreshDescription> {
  return RefreshDescription.networkRestoreRefreshO()
 }

 func modulesProviderGenerator() -> RXRDS.MPGR {
  return ModuleProvider.empty()
 }

 func contextProvider() -> CTXProvider? {
  return nil
 }

 var RXRDSShouldSendInitial: Bool { return true }

 func RXRDS() -> RXRDS {
  return RXRDS(
    modulesProviderGenerator: modulesProviderGenerator(),
    sendInitial: RXRDSShouldSendInitial
  )
 }

 func rxASDKDataSource() -> RxASDKTableDataSource {
  let dataSource = RxASDKTableDataSource()
  dataSource.contextProvider = contextProvider()
  return dataSource
 }
}

class AnyCVM<InitInput: MCVMI>: AnyModulesCVM<InitInput> {
 let generator: RXRDS.MPGR

 init(generator: @escaping RXRDS.MPGR) {
  self.generator = generator
  super.init()
 }

 override func modulesProviderGenerator() -> RXRDS.MPGR {
  return generator
 }
}

import Foundation
import RxSwift

typealias ProfileModulesC = HeaderC<UserLeafC, ProfileModulesCVM>

final class ProfileModulesCVM: AnyCVM<DefaultMCVMI> {
 final class ContextProvider: CTXProvider {
  enum ContextKey: String {
   case isProfileModulesC
  }
  
  func context(for moduleModel: ModuleModel) -> Context {
   return Context(parameters: [ContextKey.isProfileModulesC.rawValue: true])
  }
 }
 
 private let provider: ContextProvider = ContextProvider()
 
 override func contextProvider() -> CTXProvider? {
  return provider
 }
}

class ProfileMultiModulesCFactory: ALTSFC<UserLeafC> {
 private static func createPrivacyModule() -> RXRDS.FP {
  let moduleModel = ModuleModel.createEmpty(
    with: user_profile_screen_account_private(),
    image: R.image.profile_leaf_privacy_image()
  )

  return RXRDS.FP.next(LoadedModule(index: 0, data: moduleModel))
 }

 private static func createPrivacyModulesO() -> O<RXRDS.FP> {
  let events: [RXRDS.FP] = [
   createPrivacyModule(),
   .completed
  ]

  return .from(events)
 }

 private static func toModulesO(C: UserLeafC) -> O<RXRDS.FP> {
  let defaultO = O<RXRDS.FP>.never()

  guard let model = C.model, let modules = C.modules else { return defaultO }

  if model.isPrivate {
   return createPrivacyModulesO()
  } else {
   return ModuleLoader.create(modulesData: modules, emptyModule: placeholder)
  }
 }

 private static func toModulesO(placeholder: ModuleModel)
  -> (UserLeafC) -> O<RXRDS.FP> {
  return { toModulesO(C: $0, placeholder: placeholder) }
 }

 private static func createEmptyModule(for tab: ProfileTab) -> ModuleModel {
  switch tab {
  case .snaps:
   return ModuleModel.createEmpty(
     with: user_profile_screen_no_snaps_text(),
     image: R.image.profile_empty_module_snap()
   )
  case .playlists:
   return ModuleModel.createEmpty(
     with: user_profile_screen_no_playlists_text(),
     image: R.image.profile_empty_module_playlist()
   )
  }
 }

func toModulesOMapper(tab: String?) -> ((UserLeafC) -> O<RXRDS.FP>)? {
  let emptyModule: ModuleModel

  if let profileTab = tab.flatMap(ProfileTab.init(rawValue:)) {
   emptyModule = ProfileMultiModulesCFactory.createEmptyModule(for: profileTab)
  } else {
   emptyModule = ModuleModel.createEmpty(with: "No results")
  }

  return ProfileMultiModulesCFactory.toModulesO(
   placeholder: emptyModule
  )
 }

 override func createPages() -> [StretchyMultiModulesCPageProtocol] {
  let snapsLoader = getLoader(for: ProfileTab.snaps.rawValue)
  let playlistLoader = getLoader(for: ProfileTab.playlists.rawValue)

  let snapsVM = ProfileModulesCVM(generator: snapsLoader)
  let playlistVM = ProfileModulesCVM(generator: playlistLoader)

  let snapsView = ProfileModulesC()
  snapsView.inject(VM: snapsVM)

  let playlistView = ProfileModulesC()
  playlistView.inject(VM: playlistVM)

  return [
   StretchyMultiCPage(table: snapsView),
   StretchyMultiCPage(table: playlistView)
  ]
 }
}

import Foundation
import RxSwift
import RxCocoa

class ScreenCContextProvider<T>: CTXProvider {
 private let modelVariable: Variable<T?> = Variable(nil)
 private let disposeBag = DisposeBag()

 init(modelO: O<T?>) {
  modelO.bind(to: modelVariable).disposed(by: disposeBag)
 }

 final func context(for moduleModel: ModuleModel) -> Context {
  if let model = modelVariable.value {
   return context(for: model, moduleModel: moduleModel)
  } else {
   return Context()
  }
 }

 func context(for model: T, moduleModel: ModuleModel) -> Context {
  return Context()
 }
}

class AlbumScreenCContextProvider: ScreenCContextProvider<AlbumModel> {
 override func context(for model: AlbumModel, moduleModel: ModuleModel)
  -> Context {
  if moduleModel.body.id == "track_multiple_album_noheader_unlimited" {
   return Context(album: model)
  } else {
   return Context()
  }
 }
}

class PlaylistScreenCContextProvider: ScreenCContextProvider<PlaylistModel> {
 override func context(for model: PlaylistModel, moduleModel: ModuleModel) 
 -> Context {
  if moduleModel.body.id == "track_multiple_playlist_noheader_unlimited" {
   return Context(playlist: model)
  } else {
   return Context()
  }
 }
}