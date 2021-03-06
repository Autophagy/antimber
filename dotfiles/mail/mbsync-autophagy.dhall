let Prelude =
      https://prelude.dhall-lang.org/v20.0.0/package.dhall sha256:21754b84b493b98682e73f64d9d57b18e1ca36a118b81b33d0a243de8455814b

let mbsync =
      https://raw.githubusercontent.com/autophagy/dhall-mbsync/main/package.dhall sha256:2f8ebc728c7384a86b2735783eabfd582c0f94d9fc73ad29f83cb5662307a9a8

let maildir =
      mbsync.MaildirStore::{
      , name = "autophagy-local"
      , path = Some "~/mail/autophagy/"
      , inbox = "~/mail/autophagy/INBOX"
      , subFolders = Some mbsync.Subfolders.Verbatim
      }

let account =
      mbsync.Account::{
      , name = "autophagy"
      , host = Some "mail.gandi.net"
      , user = "mail@autophagy.io"
      , passCmd = Some
          "gpg --quiet --for-your-eyes-only --no-tty --decrypt ~/.msmtp-autophagy.gpg"
      , sslType = mbsync.SSLType.IMAPS
      , sslVersions = [ mbsync.SSLVersion.TLSv1_2 ]
      }

let imapStore =
      mbsync.IMAPStore::{ name = "autophagy-remote", account = "autophagy" }

let ChannelDef = { r : Text, l : Text }

let createChannel =
      \(c : ChannelDef) ->
        mbsync.Channel::{
        , name = "autophagy-" ++ Prelude.Text.replace "/" "!" c.l
        , master = ":autophagy-remote:" ++ Text/show c.r
        , slave = ":autophagy-local:" ++ c.l
        , create = mbsync.MasterSlave.Both
        , expunge = mbsync.MasterSlave.None
        , syncState = "*"
        }

let channels =
      [ { r = "Inbox", l = "INBOX" }
      , { r = "Sifetha", l = "sifetha" }
      , { r = "Inbox/mailing-lists", l = "INBOX/mailing-lists" }
      , { r = "Inbox/mailing-lists/arch-announce"
        , l = "INBOX/mailing-lists/arch-announce"
        }
      , { r = "Inbox/mailing-lists/haskell-announce"
        , l = "INBOX/mailing-lists/haskell-announce"
        }
      , { r = "Inbox/mailing-lists/haskell-cafe"
        , l = "INBOX/mailing-lists/haskell-cafe"
        }
      , { r = "Inbox/mailing-lists/qutebrowser"
        , l = "INBOX/mailing-lists/qutebrowser"
        }
      , { r = "Inbox/github", l = "INBOX/github" }
      , { r = "Inbox/newsletters", l = "INBOX/newsletters" }
      , { r = "Archives", l = "archive" }
      , { r = "Drafts", l = "drafts" }
      , { r = "Sent", l = "sent" }
      , { r = "Trash", l = "trash" }
      , { r = "Junk", l = "junk" }
      ]

let group =
      mbsync.Group::{
      , name = "autophagy"
      , channels =
          Prelude.List.map
            ChannelDef
            Text
            ( \(c : ChannelDef) ->
                "autophagy-" ++ Prelude.Text.replace "/" "!" c.l
            )
            channels
      }

in  mbsync.Mbsync::{
    , maildirStores = [ maildir ]
    , accounts = [ account ]
    , imapStores = [ imapStore ]
    , channels =
        Prelude.List.map ChannelDef mbsync.Channel.Type createChannel channels
    , groups = [ group ]
    }
