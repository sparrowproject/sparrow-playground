import SparrowTabs

public enum TabsAction {
  case newTab
  case tab(TabView.Action, for: TabID)
}
