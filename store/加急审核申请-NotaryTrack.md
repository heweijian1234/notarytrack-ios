# NotaryTrack 加急审核申请（Expedited Review）· 2026-11-12 起草

> **提交入口**（健哥网页操作，约 2 分钟）：
> https://developer.apple.com/contact/app-store/?topic=expedite
> （备选路径：ASC 右下角「Contact Us」→ App Review → Request Expedited Review）
>
> 表单只有 4 个字段，下面每个字段的英文直接复制粘贴即可。
> 表单语言随便填英文（苹果审核组看英文），不用翻译。

---

## 字段 1：App Name

```
NotaryTrack
```

## 字段 2：Apple ID of App（即 App 的 Apple/Platform ID）

```
6832398956
```

## 字段 3：This app is (单选)

选 **「A time-sensitive event」**（时间敏感事件）

> 另一个选项是 critical bug fix（在售 App 出严重故障）——NotaryTrack 是 v1.0 首发不适用。
> 时间敏感是首次发布唯一能用的理由，理由核心写"目标用户的工作流程有时效性"。

## 字段 4：Please provide details（理由正文，直接贴）

```
NotaryTrack (Apple ID 6832398956, first submission, currently Waiting for Review since Nov 8) is a record-keeping utility for independent notary signing agents in the United States.

The timing matters for these users: notary public commissions in most US states expire on a fixed statutory date, and signing agents use our app to track commission expiry dates (with a 90-day renewal heads-up), overdue payments, and client follow-ups. Many agents' commissions expire at the end of December, so December is their peak planning month — they are actively looking for and adopting tracking tools right now, before their renewal deadlines and the New Year slowdown.

Every week of review delay pushes the release into a period when our target users no longer make tooling decisions for the coming year. The app is free, contains no account system, no user-generated content, and no in-app purchases, so there is minimal review surface: a screen recording of the full app flow is already attached in the App Review Information notes (hosted at https://postwriter.cn/seo/notarytrack-review-demo.mp4).

Thank you for considering this request.
```

---

## 提交后

- 苹果一般几小时内~1天回邮件：**批准** → 排队提前，通常 24-48h 内开审；**婉拒** → 原队列继续，无任何惩罚
- 账号加急申请历史会被苹果记录，**官方要求克制使用**——本次是账号第一次申请，没问题
- 回件（无论批没批）健哥转我，我登记台账并跟进审核状态

## 依据备忘

- 官方入口 + 两个字段口径：苹果 Contact Us 表单（topic=expedite）
- "one per account"说法是讹传，官方无数字上限但记录历史、要求克制——本次首申无风险
- 提交前提满足：App 已处于 WAITING_FOR_REVIEW（11-08 18:04 提交，API 实查）
