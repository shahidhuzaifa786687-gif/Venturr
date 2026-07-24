import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from "react";
import type {
  Conversation,
  ItemPostInput,
  Listing,
  ServiceOffer,
  ServicePostInput,
} from "../types";

type PostKind = "item" | "service" | null;

interface ToastState {
  id: string;
  message: string;
}

interface AppContextValue {
  listings: Listing[];
  services: ServiceOffer[];
  conversations: Conversation[];
  savedListingIds: Set<string>;
  savedServiceIds: Set<string>;
  postKind: PostKind;
  toast: ToastState | null;
  openPost: (kind: Exclude<PostKind, null>) => void;
  closePost: () => void;
  addListing: (input: ItemPostInput) => void;
  addService: (input: ServicePostInput) => void;
  toggleSavedListing: (id: string) => void;
  toggleSavedService: (id: string) => void;
  startListingConversation: (listing: Listing, body: string) => void;
  startServiceConversation: (service: ServiceOffer, body: string) => void;
  sendMessage: (conversationId: string, body: string) => void;
  markConversationRead: (conversationId: string) => void;
  notify: (message: string) => void;
  dismissToast: () => void;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const [listings] = useState<Listing[]>([]);
  const [services] = useState<ServiceOffer[]>([]);
  const [conversations] = useState<Conversation[]>([]);
  const [savedListingIds, setSavedListingIds] = useState<Set<string>>(() => new Set());
  const [savedServiceIds, setSavedServiceIds] = useState<Set<string>>(() => new Set());
  const [postKind, setPostKind] = useState<PostKind>(null);
  const [toast, setToast] = useState<ToastState | null>(null);

  const notify = useCallback((message: string) => {
    setToast({ id: crypto.randomUUID(), message });
  }, []);

  const dismissToast = useCallback(() => setToast(null), []);

  const toggleStoredSet = useCallback(
    (
      id: string,
      setter: Dispatch<SetStateAction<Set<string>>>,
    ) => {
      setter((current) => {
        const next = new Set(current);
        if (next.has(id)) next.delete(id);
        else next.add(id);
        return next;
      });
    },
    [],
  );

  const toggleSavedListing = useCallback(
    (id: string) => {
      const wasSaved = savedListingIds.has(id);
      toggleStoredSet(id, setSavedListingIds);
      notify(wasSaved ? "Removed from saved items." : "Saved for later.");
    },
    [notify, savedListingIds, toggleStoredSet],
  );

  const toggleSavedService = useCallback(
    (id: string) => {
      const wasSaved = savedServiceIds.has(id);
      toggleStoredSet(id, setSavedServiceIds);
      notify(wasSaved ? "Removed from saved services." : "Service saved.");
    },
    [notify, savedServiceIds, toggleStoredSet],
  );

  const openPost = useCallback(
    (_kind: Exclude<PostKind, null>) => {
      setPostKind(null);
      notify("Posting unlocks after your verified campus membership is connected.");
    },
    [notify],
  );

  const addListing = useCallback(
    (_input: ItemPostInput) => {
      setPostKind(null);
      notify("No local preview listing was created.");
    },
    [notify],
  );

  const addService = useCallback(
    (_input: ServicePostInput) => {
      setPostKind(null);
      notify("No local preview service was created.");
    },
    [notify],
  );

  const startListingConversation = useCallback(
    (_listing: Listing, _body: string) => {
      notify("Messaging requires the live Supabase data connection.");
    },
    [notify],
  );

  const startServiceConversation = useCallback(
    (_service: ServiceOffer, _body: string) => {
      notify("Messaging requires the live Supabase data connection.");
    },
    [notify],
  );

  const sendMessage = useCallback(
    (_conversationId: string, _body: string) => {
      notify("No local preview message was created.");
    },
    [notify],
  );

  const markConversationRead = useCallback((_conversationId: string) => {}, []);

  const value = useMemo<AppContextValue>(
    () => ({
      listings,
      services,
      conversations,
      savedListingIds,
      savedServiceIds,
      postKind,
      toast,
      openPost,
      closePost: () => setPostKind(null),
      addListing,
      addService,
      toggleSavedListing,
      toggleSavedService,
      startListingConversation,
      startServiceConversation,
      sendMessage,
      markConversationRead,
      notify,
      dismissToast,
    }),
    [
      addListing,
      addService,
      conversations,
      dismissToast,
      listings,
      markConversationRead,
      notify,
      openPost,
      postKind,
      savedListingIds,
      savedServiceIds,
      sendMessage,
      services,
      startListingConversation,
      startServiceConversation,
      toast,
      toggleSavedListing,
      toggleSavedService,
    ],
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error("useApp must be used inside AppProvider.");
  return context;
}
